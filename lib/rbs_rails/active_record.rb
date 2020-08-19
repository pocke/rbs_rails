module RbsRails
  module ActiveRecord
    def self.class_to_rbs(klass)
      Generator.new(klass).generate
    end

    class Generator
      def initialize(klass)
        @klass = klass
      end

      def generate
        [
          klass_decl,
          relation_decl,
          collection_proxy_decl,
        ].join("\n")
      end

      private def klass_decl
        <<~RBS
          #{header}
            extend _ActiveRecord_Relation_ClassMethods[#{klass.name}, #{relation_class_name}]

          #{columns.indent(2)}
          #{associations.indent(2)}
          #{enum_instance_methods.indent(2)}
          #{enum_scope_methods(singleton: true).indent(2)}
          #{scopes(singleton: true).indent(2)}
          end
        RBS
      end

      private def relation_decl
        <<~RBS
          class #{relation_class_name} < ActiveRecord::Relation
            include _ActiveRecord_Relation[#{klass.name}]
            include Enumerable[#{klass.name}, self]
          #{enum_scope_methods(singleton: false).indent(2)}
          #{scopes(singleton: false).indent(2)}
          end
        RBS
      end

      private def collection_proxy_decl
        <<~RBS
          class #{klass.name}::ActiveRecord_Associations_CollectionProxy < ActiveRecord::Associations::CollectionProxy
          end
        RBS
      end


      private def header
        # @type var superclass: Class
        superclass = _ = klass.superclass
        "class #{klass.name} < #{superclass.name}"
      end

      private def associations
        [
          has_many,
          has_one,
          belongs_to,
        ].join("\n")
      end

      private def has_many
        klass.reflect_on_all_associations(:has_many).map do |a|
          "def #{a.name}: () -> #{a.klass.name}::ActiveRecord_Associations_CollectionProxy"
        end.join("\n")
      end

      private def has_one
        klass.reflect_on_all_associations(:has_one).map do |a|
          type = a.polymorphic? ? 'untyped' : a.klass.name
          "def #{a.name}: () -> #{type}"
        end.join("\n")
      end

      private def belongs_to
        klass.reflect_on_all_associations(:belongs_to).map do |a|
          type = a.polymorphic? ? 'untyped' : a.klass.name
          "def #{a.name}: () -> #{type}"
        end.join("\n")
      end

      private def enum_instance_methods
        # @type var methods: Array[String]
        methods = []
        enum_definitions.each do |hash|
          hash.each do |name, values|
            next if name == :_prefix || name == :_suffix

            values.each do |label, value|
              value_method_name = enum_method_name(hash, name, label)
              methods << "def #{value_method_name}!: () -> bool"
              methods << "def #{value_method_name}?: () -> bool"
            end
          end
        end

        methods.join("\n")
      end

      private def enum_scope_methods(singleton:)
        # @type var methods: Array[String]
        methods = []
        enum_definitions.each do |hash|
          hash.each do |name, values|
            next if name == :_prefix || name == :_suffix

            values.each do |label, value|
              value_method_name = enum_method_name(hash, name, label)
              methods << "def #{singleton ? 'self.' : ''}#{value_method_name}: () -> #{relation_class_name}"
            end
          end
        end
        methods.join("\n")
      end

      private def enum_definitions
        @enum_definitions ||= build_enum_definitions
      end

      # We need static analysis to detect enum.
      # ActiveRecord has `defined_enums` method,
      # but it does not contain _prefix and _suffix information.
      private def build_enum_definitions
        ast = parse_model_file
        return [] unless ast

        traverse(ast).map do |node|
          next unless node.type == :send
          next unless node.children[0].nil?
          next unless node.children[1] == :enum

          definitions = node.children[2]
          next unless definitions
          next unless definitions.type == :hash
          next unless traverse(definitions).all? { |n| [:str, :sym, :int, :hash, :pair, :true, :false].include?(n.type) }

          code = definitions.loc.expression.source
          code = "{#{code}}" if code[0] != '{'
          eval(code)
        end.compact
      end

      private def enum_method_name(hash, name, label)
        enum_prefix = hash[:_prefix]
        enum_suffix = hash[:_suffix]

        if enum_prefix == true
          prefix = "#{name}_"
        elsif enum_prefix
          prefix = "#{enum_prefix}_"
        end
        if enum_suffix == true
          suffix = "_#{name}"
        elsif enum_suffix
          suffix = "_#{enum_suffix}"
        end

        "#{prefix}#{label}#{suffix}"
      end

      private def scopes(singleton:)
        ast = parse_model_file
        return '' unless ast

        traverse(ast).map do |node|
          next unless node.type == :send
          next unless node.children[0].nil?
          next unless node.children[1] == :scope

          name_node = node.children[2]
          next unless name_node
          next unless name_node.type == :sym

          name = name_node.children[0]
          body_node = node.children[3]
          next unless body_node
          next unless body_node.type == :block

          args = args_to_type(body_node.children[1])
          "def #{singleton ? 'self.' : ''}#{name}: (#{args}) -> #{relation_class_name}"
        end.compact.join("\n")
      end

      private def args_to_type(args_node)
        # @type var res: Array[String]
        res = []
        args_node.children.each do |node|
          case node.type
          when :arg
            res << "untyped"
          when :optarg
            res << "?untyped"
          when :kwarg
            res << "#{node.children[0]}: untyped"
          when :kwoptarg
            res << "?#{node.children[0]}: untyped"
          else
            raise "unexpected: #{node}"
          end
        end
        res.join(", ")
      end

      private def parse_model_file
        return @parse_model_file if defined?(@parse_model_file)


        # @type var class_name: String
        class_name = _ = klass.name
        path = Rails.root.join('app/models/', class_name.underscore + '.rb')
        return @parse_model_file = nil unless path.exist?
        return [] unless path.exist?

        ast = Parser::CurrentRuby.parse path.read
        return @parse_model_file = nil unless path.exist?

        @parse_model_file = ast
      end

      private def traverse(node, &block)
        return to_enum(__method__, node) unless block_given?

        # @type var block: ^(Parser::AST::Node) -> untyped
        block.call node
        node.children.each do |child|
          traverse(child, &block) if child.is_a?(Parser::AST::Node)
        end
      end

      private def relation_class_name
        "#{klass.name}::ActiveRecord_Relation"
      end

      private def columns
        klass.columns.map do |col|
          class_name = sql_type_to_class(col.type)
          class_name_opt = optional(class_name)
          column_type = col.null ? class_name_opt : class_name
          sig = <<~EOS
            attr_accessor #{col.name} (): #{column_type}
            def #{col.name}_changed?: () -> bool
            def #{col.name}_change: () -> [#{class_name_opt}, #{class_name_opt}]
            def #{col.name}_will_change!: () -> void
            def #{col.name}_was: () -> #{class_name_opt}
            def #{col.name}_previously_changed?: () -> bool
            def #{col.name}_previous_change: () -> Array[#{class_name_opt}]?
            def #{col.name}_previously_was: () -> #{class_name_opt}
            def restore_#{col.name}!: () -> void
            def clear_#{col.name}_change: () -> void
          EOS
          sig << "attr_accessor #{col.name}? (): #{class_name}\n" if col.type == :boolean
          sig
        end.join("\n")
      end

      private def optional(class_name)
        class_name.include?("|") ? "(#{class_name})?" : "#{class_name}?"
      end

      private def sql_type_to_class(t)
        case t
        when :integer
          Integer.name
        when :float
          Float.name
        when :string, :text, :uuid, :binary, :enum
          String.name
        when :datetime
          # TODO
          # ActiveSupport::TimeWithZone.name
          Time.name
        when :boolean
          "TrueClass | FalseClass"
        when :jsonb, :json
          "untyped"
        when :date
          # TODO
          # Date.name
          'untyped'
        when :time
          Time.name
        when :inet
          "IPAddr"
        else
          raise "unexpected: #{t.inspect}"
        end
      end

      private
      # @dynamic klass
      attr_reader :klass
    end
  end
end
