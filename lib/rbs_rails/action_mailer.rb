module RbsRails
  module ActionMailer
    def self.class_to_rbs(klass)
      Generator.new(klass).generate
    end

    class Generator
      def initialize(klass)
        @klass = klass
        @klass_name = Util.module_name(klass, abs: false)
      end

      def generate
        Util.format_rbs klass_decl
      end

      private def klass_decl
        <<~RBS
          #{header}
          #{methods}
          #{footer}
        RBS
      end

      private def header
        namespace = +''
        klass_name(abs: false).split('::').map do |mod_name|
          namespace += "::#{mod_name}"
          mod_object = Object.const_get(namespace)
          case mod_object
          when Class
            # @type var superclass: Class
            superclass = _ = mod_object.superclass
            superclass_name = Util.module_name(superclass, abs: false)

            "class #{mod_name} < ::#{superclass_name}"
          when Module
            "module #{mod_name}"
          else
            raise 'unreachable'
          end
        end.join("\n")
      end

      private def methods
        klass.action_methods.map do |method_name|
          "def self.#{method_name}: (*untyped) -> ActionMailer::MessageDelivery"
        end.join("\n")
      end

      private def footer
        "end\n" * klass_name(abs: false).split('::').size
      end

      private def klass_name(abs: true)
        abs ? "::#{@klass_name}" : @klass_name
      end

      private
      attr_reader :klass
    end
  end
end
