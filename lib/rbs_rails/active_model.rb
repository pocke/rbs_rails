require 'bigdecimal'
require 'date'

module RbsRails
  module ActiveModel
    def self.all
      ObjectSpace.each_object.select do |obj|
        obj.is_a?(Class) && obj.ancestors.include?(::ActiveModel::Attributes) && !obj.ancestors.include?(::ActiveRecord::Base)
      rescue StandardError
        nil
      end
    end

    def self.class_to_rbs(klass)
      Generator.new(klass).generate
    end

    class Generator
      TYPES = {
        big_integer: Integer,
        binary: String,
        boolean: :bool,
        date: Date,
        datetime: DateTime,
        decimal: BigDecimal,
        float: Float,
        immutable_string: String,
        integer: Integer,
        string: String,
        time: Time
      }.freeze

      def initialize(klass)
        @klass = klass
        @klass_name = Util.module_name(klass)
      end

      def generate
        Util.format_rbs klass_decl
      end

      private def klass_decl
        <<~RBS
          #{header}
          def self.attribute: (Symbol name, ?Symbol? cast_type, ?untyped default, **untyped) -> void

          #{attributes}
          #{footer}
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

            "class #{mod_name} < ::#{superclass_name}"
          when Module
            "module #{mod_name}"
          else
            raise 'unreachable'
          end
        end.join("\n")
      end

      private def attributes
        # @type var model: untyped
        model = klass
        model.attribute_types.map do |name, type|
          attr_type = TYPES.fetch(type.type, :untyped)
          if attr_type.is_a?(Class)
            # @type var attr_type: Class
            type_name = attr_type.name
          else
            type_name = attr_type.to_s
          end
          <<~RBS
            def #{name}: () -> #{type_name}?
            def #{name}=: (#{type_name}? value) -> #{type_name}?
          RBS
        end.join("\n")
      end

      private def footer
        "end\n" * klass_name.split('::').size
      end

      private
      attr_reader :klass, :klass_name
    end
  end
end
