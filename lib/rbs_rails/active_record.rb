module RbsRails
  module ActiveRecord

    def self.generatable?(klass)
      return false if klass.abstract_class?

      klass.connection.table_exists?(klass.table_name)
    end

    def self.class_to_rbs(klass, dependencies: [])
      Generator.new(klass, dependencies: dependencies).generate
    end

    class Generator
      def initialize(klass, dependencies:)
        @klass = klass
        @dependencies = dependencies
        @klass_name = Util.module_name(klass)

        namespaces = klass_name.split('::').tap{ |names| names.pop }
        @dependencies << namespaces.join('::') unless namespaces.empty?
      end

      def generate
        Util.format_rbs klass_decl
      end

      private def klass_decl
        <<~RBS
          #{header}
            extend _ActiveRecord_Relation_ClassMethods[#{klass_name}, #{relation_class_name}, #{pk_type}]

          #{columns}
          #{associations}
          #{generated_association_methods}
          #{has_secure_password}
          #{delegated_type_instance}
          #{enum_instance_methods}
          #{scopes(singleton: true)}

          #{generated_relation_methods_decl}

          #{relation_decl}

          #{collection_proxy_decl}

          #{footer}
        RBS
      end

      private def pk_type
        pk = klass.primary_key
        return 'top' unless pk

        col = klass.columns.find {|col| col.name == pk }
        sql_type_to_class(col.type)
      end

      private def generated_relation_methods_decl
        <<~RBS
          module GeneratedRelationMethods
            #{scopes(singleton: false)}
          end
        RBS
      end

      private def relation_decl
        <<~RBS
          class #{relation_class_name} < ::ActiveRecord::Relation
            include GeneratedRelationMethods
            include _ActiveRecord_Relation[#{klass_name}, #{pk_type}]
            include Enumerable[#{klass_name}]
          end
        RBS
      end

      private def collection_proxy_decl
        <<~RBS
          class ActiveRecord_Associations_CollectionProxy < ::ActiveRecord::Associations::CollectionProxy
            include GeneratedRelationMethods
            include _ActiveRecord_Relation[#{klass_name}, #{pk_type}]
          end
        RBS
      end

      private def header
        namespace = +''
        klass_name.split('::').map do |mod_name|
          namespace += "::#{mod_name}"
          mod_object = Object.const_get(namespace)
          case mod_object
          when Class
            # @type var superclass: Class
            superclass = _ = mod_object.superclass
            superclass_name = Util.module_name(superclass)
            @dependencies << superclass_name

            "class #{mod_name} < ::#{superclass_name}"
          when Module
            "module #{mod_name}"
          else
            raise 'unreachable'
          end
        end.join("\n")
      end

      private def footer
        "end\n" * klass_name.split('::').size
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
          @dependencies << a.klass.name

          singular_name = a.name.to_s.singularize
          type = Util.module_name(a.klass)
          collection_type = "#{type}::ActiveRecord_Associations_CollectionProxy"
          @dependencies << collection_type

          <<~RUBY.chomp
            def #{a.name}: () -> #{collection_type}
            def #{a.name}=: (#{collection_type} | Array[#{type}]) -> (#{collection_type} | Array[#{type}])
            def #{singular_name}_ids: () -> Array[Integer]
            def #{singular_name}_ids=: (Array[Integer]) -> Array[Integer]
          RUBY
        end.join("\n")
      end

      private def has_one
        klass.reflect_on_all_associations(:has_one).map do |a|
          @dependencies << a.klass.name unless a.polymorphic?

          type = a.polymorphic? ? 'untyped' : Util.module_name(a.klass)
          type_optional = optional(type)
          <<~RUBY.chomp
            def #{a.name}: () -> #{type_optional}
            def #{a.name}=: (#{type_optional}) -> #{type_optional}
            def build_#{a.name}: (untyped) -> #{type}
            def create_#{a.name}: (untyped) -> #{type}
            def create_#{a.name}!: (untyped) -> #{type}
            def reload_#{a.name}: () -> #{type_optional}
          RUBY
        end.join("\n")
      end

      private def belongs_to
        klass.reflect_on_all_associations(:belongs_to).map do |a|
          @dependencies << a.klass.name unless a.polymorphic?

          type = a.polymorphic? ? 'untyped' : Util.module_name(a.klass)
          type_optional = optional(type)
          # @type var methods: Array[String]
          methods = []
          methods << "def #{a.name}: () -> #{type}"
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

      private def generated_association_methods
        # @type var sigs: Array[String]
        sigs = []

        # Needs to require "active_storage/engine"
        if klass.respond_to?(:attachment_reflections)
          sigs << "module GeneratedAssociationMethods"
          sigs << klass.attachment_reflections.map do |name, reflection|
            case reflection.macro
            when :has_one_attached
              <<~EOS
                def #{name}: () -> ActiveStorage::Attached::One
                def #{name}=: (ActionDispatch::Http::UploadedFile) -> ActionDispatch::Http::UploadedFile
                            | (Rack::Test::UploadedFile) -> Rack::Test::UploadedFile
                            | (ActiveStorage::Blob) -> ActiveStorage::Blob
                            | (String) -> String
                            | ({ io: IO, filename: String, content_type: String? }) -> { io: IO, filename: String, content_type: String? }
                            | (nil) -> nil
              EOS
            when :has_many_attached
              <<~EOS
                def #{name}: () -> ActiveStorage::Attached::Many
                def #{name}=: (untyped) -> untyped
              EOS
            else
              raise
            end
          end.join("\n")
          sigs << "end"
          sigs << "include GeneratedAssociationMethods"
        end

        sigs.join("\n")
      end

      private def delegated_type_instance
        definitions = delegated_type_definitions
        return "" unless definitions
        # @type var methods: Array[String]
        methods = []
        definitions.each do |definition|
          methods << "def #{definition[:role]}_class: () -> Class"
          methods << "def #{definition[:role]}_name: () -> String"
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

      private def delegated_type_definitions
        # def delegated_type(role, types:, **options)
        CallTracer.result(klass.method(:delegated_type))
      end

      private def has_secure_password
        CallTracer.result(klass.method(:has_secure_password)).map do |arguments|
          # def has_secure_password(attribute = :password, validations: true)
          attribute = arguments[:attribute]
          <<~EOS
            module ActiveModel_SecurePassword_InstanceMethodsOnActivation_#{attribute}
              attr_reader #{attribute}: String?
              def #{attribute}=: (String) -> String
              def #{attribute}_confirmation=: (String) -> String
              def authenticate_#{attribute}: (String) -> (#{klass_name} | false)
              #{attribute == :password ? "alias authenticate authenticate_password" : ""}
            end
            include ActiveModel_SecurePassword_InstanceMethodsOnActivation_#{attribute}
          EOS
        end.join("\n")
      end

      private def enum_instance_methods
        # @type var methods: Array[String]
        methods = []
        enum_definitions.each do |hash|
          hash.each do |name, values|
            next if name == :_prefix || name == :_suffix || name == :_default

            values.each do |label, value|
              value_method_name = enum_method_name(hash, name, label)
              methods << "def #{value_method_name}!: () -> bool"
              methods << "def #{value_method_name}?: () -> bool"
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
        CallTracer.result(klass.method(:enum)).to_a.map do |arguments|
          # def enum(definitions)
          arguments[:definitions]
        end
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
        prefix = singleton ? 'self.' : ''

        sigs = CallTracer.result(klass.method(:scope)).filter_map do |arguments|
          # def scope(name, body, &block)
          name = arguments[:name]
          body = arguments[:body]
          next unless body.kind_of?(Proc)

          args_type = parameters_to_type(body.parameters)
          "def #{prefix}#{name}: #{args_type} -> #{relation_class_name}"
        end

        sigs.join("\n")
      end

      private def parameters_to_type(parameters)
        # @type var res: Array[String]
        res = []
        # @type var block: String?
        block = nil
        parameters.each do |(type, name)|
          case type
          when :req
            res << "untyped `#{name}`"
          when :opt
            res << "?untyped `#{name}`"
          when :keyreq
            res << "#{name}: untyped"
          when :key
            res << "?#{name}: untyped"
          when :rest
            res << "*untyped `#{name}`"
          when :keyrest
            res << "**untyped `#{name}`"
          when :block
            block = " { (*untyped) -> untyped }"
          else
            raise "unexpected: #{type}"
          end
        end
        "(#{res.join(", ")})#{block}"
      end

      private def relation_class_name
        "ActiveRecord_Relation"
      end

      private def columns
        mod_sig = +"module GeneratedAttributeMethods\n"
        mod_sig << klass.columns.map do |col|
          class_name = if enum_definitions.any? { |hash| hash.key?(col.name) || hash.key?(col.name.to_sym) }
                         'String'
                       else
                         sql_type_to_class(col.type)
                       end
          class_name_opt = optional(class_name)
          column_type = col.null ? class_name_opt : class_name
          sig = <<~EOS
            def #{col.name}: () -> #{column_type}
            def #{col.name}=: (#{column_type}) -> #{column_type}
            def #{col.name}?: () -> bool
            def #{col.name}_changed?: () -> bool
            def #{col.name}_change: () -> [#{class_name_opt}, #{class_name_opt}]
            def #{col.name}_will_change!: () -> void
            def #{col.name}_was: () -> #{class_name_opt}
            def #{col.name}_previously_changed?: () -> bool
            def #{col.name}_previous_change: () -> Array[#{class_name_opt}]?
            def #{col.name}_previously_was: () -> #{class_name_opt}
            def #{col.name}_before_last_save: () -> #{class_name_opt}
            def #{col.name}_change_to_be_saved: () -> Array[#{class_name_opt}]?
            def #{col.name}_in_database: () -> #{class_name_opt}
            def saved_change_to_#{col.name}: () -> Array[#{class_name_opt}]?
            def saved_change_to_#{col.name}?: () -> bool
            def will_save_change_to_#{col.name}?: () -> bool
            def restore_#{col.name}!: () -> void
            def clear_#{col.name}_change: () -> void
          EOS
          sig << "\n"
          sig
        end.join("\n")
        mod_sig << "\nend\n"
        mod_sig << "include GeneratedAttributeMethods"
        mod_sig
      end

      private def optional(class_name)
        class_name.include?("|") ? "(#{class_name})?" : "#{class_name}?"
      end

      private def sql_type_to_class(t)
        case t
        when :integer
          'Integer'
        when :float
          'Float'
        when :decimal
          'BigDecimal'
        when :string, :text, :citext, :uuid, :binary
          'String'
        when :datetime
          'ActiveSupport::TimeWithZone'
        when :boolean
          "bool"
        when :jsonb, :json
          "untyped"
        when :date
          'Date'
        when :time
          'Time'
        when :inet
          "IPAddr"
        else
          # Unknown column type, give up
          'untyped'
        end
      end

      private
      attr_reader :klass, :klass_name
    end
  end
end
