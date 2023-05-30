module RbsRails
  module ActionController

    def self.user_defined_controller?(klass)
      methods = klass.methods(false).map{|m| klass.method(m)} +
        klass.instance_methods(false).map{|m| klass.instance_method(m)}
      source_locations = methods.filter_map(&:source_location)
      source_locations.first&.first&.start_with?(Rails.root.to_s)
    end

    def self.class_to_rbs(klass, dependencies: [])
      Generator.new(klass, dependencies: dependencies).generate
    end

    class Generator
      def initialize(klass, dependencies:)
        @klass = klass
      end

      def generate
        Util.format_rbs klass_decl
      end

      private def klass_decl
        <<~RBS
          #{header}
          #{footer}
        RBS
      end

      private def header
        namespace = +''
        module_defs = klass.module_parents.reverse[1..].map do |mod|
          module_name = mod.name.split('::').last
          "module #{module_name}"
        end

        superclass = _ = klass.superclass
        superclass_name = Util.module_name(superclass)
        class_name = klass.name.split('::').last
        class_def = "class #{class_name} < ::#{superclass_name}"

        (module_defs + [class_def]).join("\n")
      end

      private def footer
        "end\n" * klass.module_parents.size
      end

      private
      attr_reader :klass
    end
  end
end
