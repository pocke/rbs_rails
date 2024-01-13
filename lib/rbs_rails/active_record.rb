module RbsRails
  module ActiveRecord

    # @rbs klass: untyped
    def self.generatable?(klass) #: boolish
      return false if klass.abstract_class?

      klass.connection.table_exists?(klass.table_name)
    end

    # @rbs klass: untyped
    # @rbs dependencies: Array[String]
    def self.class_to_rbs(klass) #: untyped
      Generator.new(klass).generate
    end

    class Generator
      IGNORED_ENUM_KEYS = %i[_prefix _suffix _default _scopes] #: Array[Symbol]

      # @rbs @parse_model_file: nil | Parser::AST::Node
      # @rbs @enum_definitions: Array[Hash[Symbol, untyped]]
      # @rbs @klass_name: String

      attr_reader :dependencies #: DependencyBuilder

      # @rbs klass: singleton(ActiveRecord::Base) & Enum
      def initialize(klass) #: untyped
        @klass = klass
        @dependencies = DependencyBuilder.new
        @klass_name = Util.module_name(klass, abs: false)

        namespaces = klass_name(abs: false).split('::').tap{ |names| names.pop }
        @dependencies << namespaces.join('::') unless namespaces.empty?
      end

      def generate #: String
        Util.format_rbs klass_decl
      end

      private def klass_decl #: String
        <<~RBS
          # resolve-type-names: false

          #{header}
            extend ::ActiveRecord::Base::ClassMethods[#{klass_name}, #{relation_class_name}, #{pk_type}]

          #{columns}
          #{alias_columns}
          #{associations}
          #{generated_association_methods}
          #{has_secure_password}
          #{delegated_type_instance}
          #{delegated_type_scope(singleton: true)}
          #{enum_instance_methods}
          #{enum_class_methods(singleton: true)}
          #{pluck_overloads}
          #{scopes(singleton: true)}

          #{generated_relation_methods_decl}

          #{relation_decl}

          #{collection_proxy_decl}

          #{footer}

          #{dependencies.build}
        RBS
      end

      private def pk_type #: String
        pk = klass.primary_key
        return 'top' unless pk

        col = klass.columns.find {|col| col.name == pk }
        sql_type_to_class(col.type)
      end

      private def generated_relation_methods_decl #: String
        <<~RBS
          module #{generated_relation_methods_name}
            #{enum_class_methods(singleton: false)}
            #{scopes(singleton: false)}
            #{delegated_type_scope(singleton: false)}
          end
        RBS
      end

      private def relation_decl #: String
        <<~RBS
          class #{relation_class_name} < ::ActiveRecord::Relation
            include ::Enumerable[#{klass_name}]
            include #{generated_relation_methods_name}
            include ::ActiveRecord::Relation::Methods[#{klass_name}, #{pk_type}]

            #{pluck_overloads_instance}
          end
        RBS
      end

      private def collection_proxy_decl #: String
        <<~RBS
          class #{klass_name}::ActiveRecord_Associations_CollectionProxy < ::ActiveRecord::Associations::CollectionProxy
            include ::Enumerable[#{klass_name}]
            include #{generated_relation_methods_name}
            include ::ActiveRecord::Relation::Methods[#{klass_name}, #{pk_type}]

            def build: (?::ActiveRecord::Associations::CollectionProxy::_EachPair attributes) ?{ () -> untyped } -> #{klass_name}
                     | (::Array[::ActiveRecord::Associations::CollectionProxy::_EachPair] attributes) ?{ () -> untyped } -> ::Array[#{klass_name}]
            def create: (?::ActiveRecord::Associations::CollectionProxy::_EachPair attributes) ?{ () -> untyped } -> #{klass_name}
                      | (::Array[::ActiveRecord::Associations::CollectionProxy::_EachPair] attributes) ?{ () -> untyped } -> ::Array[#{klass_name}]
            def create!: (?::ActiveRecord::Associations::CollectionProxy::_EachPair attributes) ?{ () -> untyped } -> #{klass_name}
                       | (::Array[::ActiveRecord::Associations::CollectionProxy::_EachPair] attributes) ?{ () -> untyped } -> ::Array[#{klass_name}]
            def reload: () -> ::Array[#{klass_name}]

            def replace: (::Array[#{klass_name}]) -> void
            def delete: (*#{klass_name} | #{pk_type}) -> ::Array[#{klass_name}]
            def destroy: (*#{klass_name} | #{pk_type}) -> ::Array[#{klass_name}]
            def <<: (*#{klass_name} | ::Array[#{klass_name}]) -> self
            def prepend: (*#{klass_name} | ::Array[#{klass_name}]) -> self
            #{pluck_overloads_instance}
          end
        RBS
      end

      private def header #: String
        namespace = +''
        klass_name(abs: false).split('::').map do |mod_name|
          namespace += "::#{mod_name}"
          mod_object = Object.const_get(namespace)
          case mod_object
          when Class
            # @type var superclass: Class
            superclass = _ = mod_object.superclass
            superclass_name = Util.module_name(superclass, abs: false)
            @dependencies << superclass_name

            "class #{namespace} < ::#{superclass_name}"
          when Module
            "module #{namespace}"
          else
            raise 'unreachable'
          end
        end.join("\n")
      end

      private def footer #: String
        "end\n" * klass_name(abs: false).split('::').size
      end

      private def associations #: String
        [
          has_many,
          has_and_belongs_to_many,
          has_one,
          belongs_to,
        ].join("\n")
      end

      private def has_many #: String
        klass.reflect_on_all_associations(:has_many).map do |a|
          @dependencies << a.klass.name

          singular_name = a.name.to_s.singularize
          type = Util.module_name(a.klass)
          collection_type = "#{type}::ActiveRecord_Associations_CollectionProxy"
          @dependencies << collection_type

          <<~RUBY.chomp
            def #{a.name}: () -> #{collection_type}
            def #{a.name}=: (#{collection_type} | ::Array[#{type}]) -> (#{collection_type} | ::Array[#{type}])
            def #{singular_name}_ids: () -> ::Array[::Integer]
            def #{singular_name}_ids=: (::Array[::Integer]) -> ::Array[::Integer]
          RUBY
        end.join("\n")
      end

      private def has_and_belongs_to_many #: String
        klass.reflect_on_all_associations(:has_and_belongs_to_many).map do |a|
          @dependencies << a.klass.name

          singular_name = a.name.to_s.singularize
          type = Util.module_name(a.klass)
          collection_type = "#{type}::ActiveRecord_Associations_CollectionProxy"
          @dependencies << collection_type

          <<~RUBY.chomp
            def #{a.name}: () -> #{collection_type}
            def #{a.name}=: (#{collection_type} | ::Array[#{type}]) -> (#{collection_type} | ::Array[#{type}])
            def #{singular_name}_ids: () -> ::Array[::Integer]
            def #{singular_name}_ids=: (::Array[::Integer]) -> ::Array[::Integer]
          RUBY
        end.join("\n")
      end

      private def has_one #: String
        klass.reflect_on_all_associations(:has_one).map do |a|
          @dependencies << a.klass.name unless a.polymorphic?

          type = a.polymorphic? ? 'untyped' : Util.module_name(a.klass)
          type_optional = optional(type)
          <<~RUBY.chomp
            def #{a.name}: () -> #{type_optional}
            def #{a.name}=: (#{type_optional}) -> #{type_optional}
            def build_#{a.name}: (?untyped) -> #{type}
            def create_#{a.name}: (?untyped) -> #{type}
            def create_#{a.name}!: (?untyped) -> #{type}
            def reload_#{a.name}: () -> #{type_optional}
          RUBY
        end.join("\n")
      end

      private def belongs_to #: String
        klass.reflect_on_all_associations(:belongs_to).map do |a|
          @dependencies << a.klass.name unless a.polymorphic?

          is_optional = a.options[:optional]

          type = a.polymorphic? ? 'untyped' : Util.module_name(a.klass)
          type_optional = optional(type)
          # @type var methods: Array[String]
          methods = []
          methods << "def #{a.name}: () -> #{is_optional ? type_optional : type}"
          methods << "def #{a.name}=: (#{type_optional}) -> #{type_optional}"
          methods << "def reload_#{a.name}: () -> #{type_optional}"
          if !a.polymorphic?
            methods << "def build_#{a.name}: (untyped) -> #{type}"
            methods << "def create_#{a.name}: (untyped) -> #{type}"
            methods << "def create_#{a.name}!: (untyped) -> #{type}"
          end
          methods.join("\n")
        end.join("\n")
      end

      private def generated_association_methods #: String
        # @type var sigs: Array[String]
        sigs = []

        # Needs to require "active_storage/engine"
        if klass.respond_to?(:attachment_reflections)
          sigs << "module #{klass_name}::GeneratedAssociationMethods"
          sigs << klass.attachment_reflections.map do |name, reflection|
            case reflection.macro
            when :has_one_attached
              <<~EOS
                def #{name}: () -> ::ActiveStorage::Attached::One
                def #{name}=: (::ActionDispatch::Http::UploadedFile) -> ::ActionDispatch::Http::UploadedFile
                            | (::Rack::Test::UploadedFile) -> ::Rack::Test::UploadedFile
                            | (::ActiveStorage::Blob) -> ::ActiveStorage::Blob
                            | (::String) -> ::String
                            | ({ io: ::IO, filename: ::String, content_type: ::String? }) -> { io: ::IO, filename: ::String, content_type: ::String? }
                            | (nil) -> nil
              EOS
            when :has_many_attached
              <<~EOS
                def #{name}: () -> ::ActiveStorage::Attached::Many
                def #{name}=: (untyped) -> untyped
              EOS
            else
              raise "unknown macro: #{reflection.macro}"
            end
          end.join("\n")
          sigs << "end"
          sigs << "include #{klass_name}::GeneratedAssociationMethods"
        end

        sigs.join("\n")
      end

      # @rbs singleton: bool
      private def delegated_type_scope(singleton:) #: String
        definitions = delegated_type_definitions
        return "" unless definitions
        definitions.map do |definition|
          definition[:types].map do |type|
            scope_name = type.tableize.gsub("/", "_")
            "def #{singleton ? 'self.' : ''}#{scope_name}: () -> #{relation_class_name}"
          end
        end.flatten.join("\n")
      end

      private def delegated_type_instance #: String
        definitions = delegated_type_definitions
        return "" unless definitions
        # @type var methods: Array[String]
        methods = []
        definitions.each do |definition|
          methods << "def #{definition[:role]}_class: () -> ::Class"
          methods << "def #{definition[:role]}_name: () -> ::String"
          methods << definition[:types].map do |type|
            scope_name = type.tableize.gsub("/", "_")
            singular = scope_name.singularize
            <<~RUBY.chomp
              def #{singular}?: () -> bool
              def #{singular}: () -> #{type.classify}?
              def #{singular}_id: () -> Integer?
            RUBY
          end.join("\n")
        end
        methods.join("\n")
      end

      private def delegated_type_definitions #: Array[{ role: Symbol, types: Array[String] }]?
        ast = parse_model_file
        return unless ast

        traverse(ast).map do |node|
          # @type block: { role: Symbol, types: Array[String] }?
          next unless node.type == :send
          next unless node.children[0].nil?
          next unless node.children[1] == :delegated_type

          role_node = node.children[2]
          next unless role_node
          next unless role_node.type == :sym
          # @type var role: Symbol
          role = role_node.children[0]

          args_node = node.children[3]
          next unless args_node
          next unless args_node.type == :hash

          types = traverse(args_node).map do |n|
            # @type block: Array[String]?
            next unless n.type == :pair
            key_node = n.children[0]
            next unless key_node
            next unless key_node.type == :sym
            next unless key_node.children[0] == :types

            types_node = n.children[1]
            next unless types_node
            next unless types_node.type == :array
            code = types_node.loc.expression.source
            eval(code)
          end.compact.flatten

          { role: role, types: types }
        end.compact
      end

      private def has_secure_password #: String?
        ast = parse_model_file
        return unless ast

        traverse(ast).map do |node|
          # @type block: String?
          next unless node.type == :send
          next unless node.children[0].nil?
          next unless node.children[1] == :has_secure_password

          attribute_node = node.children[2]
          attribute = if attribute_node && attribute_node.type == :sym
                        attribute_node.children[0]
                      else
                        :password
                      end

          <<~EOS
            module #{klass_name}::ActiveModel_SecurePassword_InstanceMethodsOnActivation_#{attribute}
              attr_reader #{attribute}: ::String?
              def #{attribute}=: (::String) -> ::String
              def #{attribute}_confirmation=: (::String) -> ::String
              def authenticate_#{attribute}: (::String) -> (#{klass_name} | false)
              #{attribute == :password ? "alias authenticate authenticate_password" : ""}
            end
            include #{klass_name}::ActiveModel_SecurePassword_InstanceMethodsOnActivation_#{attribute}
          EOS
        end.compact.join("\n")
      end

      private def enum_instance_methods #: String
        # @type var methods: Array[String]
        methods = []
        klass.enum_definitions.each do |_, method_name|
          methods << "def #{method_name}!: () -> bool"
          methods << "def #{method_name}?: () -> bool"
        end

        methods.join("\n")
      end

      # @rbs singleton: untyped
      private def enum_class_methods(singleton:) #: String
        # @type var methods: Array[String]
        methods = []
        klass.enum_definitions.map(&:first).uniq.each do |name|
          column = klass.columns_hash[name.to_s] || klass.columns_hash[klass.attribute_aliases[name.to_s]]
          class_name = sql_type_to_class(column.type)
          methods << "def #{singleton ? 'self.' : ''}#{name.to_s.pluralize}: () -> ::ActiveSupport::HashWithIndifferentAccess[::String, #{class_name}]"
        end
        klass.enum_definitions.each do |_, method_name|
          methods << "def #{singleton ? 'self.' : ''}#{method_name}: () -> #{relation_class_name}"
          methods << "def #{singleton ? 'self.' : ''}not_#{method_name}: () -> #{relation_class_name}"
        end
        methods.join("\n")
      end

      # @rbs singleton: untyped
      private def scopes(singleton:) #: untyped
        ast = parse_model_file
        return '' unless ast

        prefix = singleton ? 'self.' : ''

        sigs = traverse(ast).map do |node|
          # @type block: nil | String
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
          "def #{prefix}#{name}: #{args} -> #{relation_class_name}"
        end.compact

        if klass.respond_to?(:attachment_reflections)
          klass.attachment_reflections.each do |name, _reflection|
            sigs << "def #{prefix}with_attached_#{name}: () -> #{relation_class_name}"
          end
        end

        sigs.join("\n")
      end

      # @rbs args_node: untyped
      private def args_to_type(args_node) #: untyped
        # @type var res: Array[String]
        res = []
        # @type var block: String?
        block = nil
        args_node.children.each do |node|
          case node.type
          when :arg
            res << "untyped `#{node.children[0]}`"
          when :optarg
            res << "?untyped `#{node.children[0]}`"
          when :kwarg
            res << "#{node.children[0]}: untyped"
          when :kwoptarg
            res << "?#{node.children[0]}: untyped"
          when :restarg
            res << "*untyped `#{node.children[0]}`"
          when :kwrestarg
            res << "**untyped `#{node.children[0]}`"
          when :blockarg
            block = " { (*untyped) -> untyped }"
          else
            raise "unexpected: #{node}"
          end
        end
        "(#{res.join(", ")})#{block}"
      end

      private def pluck_overloads #: String
        sigs = klass.columns.map do |col|
          class_name = if klass.enum_definitions.any? { |name, _| name == col.name.to_sym }
                         '::String'
                       else
                         sql_type_to_class(col.type)
                       end
          class_name_opt = optional(class_name)
          column_type = col.null ? class_name_opt : class_name
          "(:#{col.name} | \"#{col.name}\") -> ::Array[#{column_type}]"
        end
        "def self.pluck: #{sigs.join(' | ')} | ..."
      end

      private def pluck_overloads_instance #: String
        sigs = klass.columns.map do |col|
          class_name = if klass.enum_definitions.any? { |name, _| name == col.name.to_sym }
                         '::String'
                       else
                         sql_type_to_class(col.type)
                       end
          class_name_opt = optional(class_name)
          column_type = col.null ? class_name_opt : class_name
          "(:#{col.name} | \"#{col.name}\") -> ::Array[#{column_type}]"
        end

        "def pluck: #{sigs.join(' | ')} | ..."
      end

      private def parse_model_file #: untyped
        return @parse_model_file if defined?(@parse_model_file)

        path, _line = Object.const_source_location(klass.name) rescue nil
        return @parse_model_file = nil unless path

        begin
          @parse_model_file = Parser::CurrentRuby.parse File.read(path)
        rescue => e
          @parse_model_file = nil
        end
      end

      #: (Parser::AST::Node) { (Parser::AST::Node) -> untyped } -> untyped
      #: (Parser::AST::Node) -> Enumerator[Parser::AST::Node, untyped]
      private def traverse(node, &block)
        return to_enum(__method__ || raise, node) unless block

        block.call node
        node.children.each do |child|
          traverse(child, &block) if child.is_a?(Parser::AST::Node)
        end
      end

      private def relation_class_name #: String
        "#{klass_name}::ActiveRecord_Relation"
      end

      # @rbs abs: boolish
      private def klass_name(abs: true) #: String
        abs ? "::#{@klass_name}" : @klass_name
      end

      private def generated_relation_methods_name #: String
        "#{klass_name}::GeneratedRelationMethods"
      end


      private def columns #: untyped
        mod_sig = +"module #{klass_name}::GeneratedAttributeMethods\n"
        mod_sig << klass.columns.map do |col|
          # NOTE:
          #   `klass.attribute_types[col.name].try(:coder)` is for Rails 6.0 and before
          #   `klass.attribute_types[col.name]&.instance_variable_get(:@coder)` is for Rails 6.1 and after
          col_serializer = klass.attribute_types[col.name].try(:coder) ||
                           klass.attribute_types[col.name]&.instance_variable_get(:@coder)
          # e.g. ActiveRecord::Coders::JSON
          #      if your model has `serialize ..., JSON`
          # e.g. #<ActiveRecord::Coders::YAMLColumn:0x0000aaaafdc54970 @attr_name=..., @object_class=Array>
          #      if your model has `serialize ..., Array`
          # etc.
          col_serialize_to = col_serializer.try(:object_class)&.name
          if col_serializer.is_a?(Class) && col_serializer.name == 'ActiveRecord::Coders::JSON'
            class_name = 'untyped' # JSON
          elsif col_serialize_to == 'Array'
            class_name = '::Array[untyped]' # Array
          elsif col_serialize_to == 'Hash'
            class_name = '::Hash[untyped, untyped]' # Hash
          else
            class_name = if klass.enum_definitions.any? { |name, _| name == col.name.to_sym }
                           '::String'
                         else
                           sql_type_to_class(col.type)
                         end
          end
          sql_class_name = col.type == :datetime ? '::Time' : sql_type_to_class(col.type)
          # If the DB says the column can be null, we need `<type>?`
          # ...but if the type is already `untyped` there's no point in writing `untyped?`
          class_name_opt = (class_name == 'untyped') ? 'untyped' : optional(class_name)
          column_type = col.null ? class_name_opt : class_name
          sql_column_type = col.null ? optional(sql_class_name) : sql_class_name
          sig = <<~EOS
            def #{col.name}: () -> #{column_type}
            def #{col.name}=: (#{column_type}) -> #{column_type}
            def #{col.name}?: () -> bool
            def #{col.name}_changed?: () -> bool
            def #{col.name}_change: () -> [#{class_name_opt}, #{class_name_opt}]
            def #{col.name}_will_change!: () -> void
            def #{col.name}_was: () -> #{class_name_opt}
            def #{col.name}_previously_changed?: () -> bool
            def #{col.name}_previous_change: () -> ::Array[#{class_name_opt}]?
            def #{col.name}_previously_was: () -> #{class_name_opt}
            def #{col.name}_before_last_save: () -> #{class_name_opt}
            def #{col.name}_change_to_be_saved: () -> ::Array[#{class_name_opt}]?
            def #{col.name}_in_database: () -> #{class_name_opt}
            def saved_change_to_#{col.name}: () -> ::Array[#{class_name_opt}]?
            def saved_change_to_#{col.name}?: () -> bool
            def will_save_change_to_#{col.name}?: () -> bool
            def restore_#{col.name}!: () -> void
            def clear_#{col.name}_change: () -> void
            def #{col.name}_before_type_cast: () -> #{sql_column_type}
            def #{col.name}_for_database: () -> #{sql_column_type}
          EOS
          sig << "\n"
          sig
        end.join("\n")
        mod_sig << "\nend\n"
        mod_sig << "include #{klass_name}::GeneratedAttributeMethods"
        mod_sig
      end

      private def alias_columns
        attribute_aliases = klass.attribute_aliases
        attribute_aliases["id_value"] ||= "id" if klass.attribute_names.include?("id")

        mod_sig = +"module #{klass_name}::GeneratedAliasAttributeMethods\n"
        mod_sig << "include #{klass_name}::GeneratedAttributeMethods\n"
        mod_sig << attribute_aliases.map do |col|
          sig = <<~EOS
            alias #{col[0]} #{col[1]}
            alias #{col[0]}= #{col[1]}=
            alias #{col[0]}? #{col[1]}?
            alias #{col[0]}_changed? #{col[1]}_changed?
            alias #{col[0]}_change #{col[1]}_change
            alias #{col[0]}_will_change! #{col[1]}_will_change!
            alias #{col[0]}_was #{col[1]}_was
            alias #{col[0]}_previously_changed? #{col[1]}_previously_changed?
            alias #{col[0]}_previous_change #{col[1]}_previous_change
            alias #{col[0]}_previously_was #{col[1]}_previously_was
            alias #{col[0]}_before_last_save #{col[1]}_before_last_save
            alias #{col[0]}_change_to_be_saved #{col[1]}_change_to_be_saved
            alias #{col[0]}_in_database #{col[1]}_in_database
            alias saved_change_to_#{col[0]} saved_change_to_#{col[1]}
            alias saved_change_to_#{col[0]}? saved_change_to_#{col[1]}?
            alias will_save_change_to_#{col[0]}? will_save_change_to_#{col[1]}?
            alias restore_#{col[0]}! restore_#{col[1]}!
            alias clear_#{col[0]}_change clear_#{col[1]}_change
            alias #{col[0]}_before_type_cast #{col[1]}_before_type_cast
            alias #{col[0]}_for_database #{col[1]}_for_database
          EOS
          sig << "\n"
          sig
        end.join("\n")
        mod_sig << "\nend\n"
        mod_sig << "include #{klass_name}::GeneratedAliasAttributeMethods"
        mod_sig
      end

      # @rbs class_name: String
      private def optional(class_name) #: String
        class_name.include?("|") ? "(#{class_name})?" : "#{class_name}?"
      end

      # @rbs t: untyped
      private def sql_type_to_class(t) #: untyped
        case t
        when :integer
          '::Integer'
        when :float
          '::Float'
        when :decimal
          '::BigDecimal'
        when :string, :text, :citext, :uuid, :binary
          '::String'
        when :datetime
          '::ActiveSupport::TimeWithZone'
        when :boolean
          "bool"
        when :jsonb, :json
          "untyped"
        when :date
          '::Date'
        when :time
          '::Time'
        when :inet
          "::IPAddr"
        else
          # Unknown column type, give up
          'untyped'
        end
      end

      private
      attr_reader :klass #: singleton(ActiveRecord::Base) & Enum
    end
  end
end
