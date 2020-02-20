module RbsRails
  module ActiveRecord
    def self.class_to_rbs(klass, mode:)
      Generator.new(klass, mode: mode).generate
    end

    class Generator
      def initialize(klass, mode:)
        @klass = klass
        @mode = mode
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
          end
        RBS
      end

      private def relation_decl
        <<~RBS
          class #{relation_class_name} < ActiveRecord::Relation
            include _ActiveRecord_Relation[#{klass.name}]
            include Enumerable[#{klass.name}, self]
          #{enum_scope_methods(singleton: false).indent(2)}
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
        case mode
        when :extension
          "extension #{klass.name} (RbsRails)"
        when :class
          "class #{klass.name} < #{klass.superclass.name}"
        else
          raise "unexpected mode: #{mode}"
        end
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
        path = Rails.root.join('app/models/', klass.name.underscore + '.rb')
        return [] unless path.exist?

        ast = Parser::CurrentRuby.parse path.read
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

      private def traverse(node, &block)
        return to_enum(__method__, node) unless block_given?

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
          "attr_accessor #{col.name} (): #{sql_type_to_class(col.type)}"
        end.join("\n")
      end

      private def sql_type_to_class(t)
        case t
        when :integer
          Integer.name
        when :string, :text, :uuid
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
        else
          raise "unexpected: #{t.inspect}"
        end
      end

      private
      attr_reader :klass, :mode
    end
  end
end
