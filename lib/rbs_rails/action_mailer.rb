module RbsRails
  module ActionMailer
    # @rbs klass: singleton(ActionMailer::Base)
    def self.class_to_rbs(klass) #: String
      Generator.new(klass).generate
    end

    class Generator
      # @rbs @klass_name: String

      # @rbs klass: singleton(ActionMailer::Base)
      def initialize(klass) #: void
        @klass = klass
        @klass_name = Util.module_name(klass, abs: false)
      end

      def generate #: String
        Util.format_rbs klass_decl
      end

      private def klass_decl #: String
        <<~RBS
          # resolve-type-names: false

          #{header}
          #{methods}
          #{footer}
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

            "class #{namespace} < ::#{superclass_name}"
          when Module
            "module #{namespace}"
          else
            raise 'unreachable'
          end
        end.join("\n")
      end

      private def methods #: String
        klass.action_methods.map do |method_name|
          "def self.#{method_name}: (*untyped) -> ::ActionMailer::MessageDelivery"
        end.join("\n")
      end

      private def footer #: String
        "end\n" * klass_name(abs: false).split('::').size
      end

      # @rbs abs: bool
      private def klass_name(abs: true) #: String
        abs ? "::#{@klass_name}" : @klass_name
      end

      private
      attr_reader :klass #: singleton(ActionMailer::Base)
    end
  end
end
