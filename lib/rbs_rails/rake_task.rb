require 'rake'
require 'rake/tasklib'

module RbsRails
  class RakeTask < Rake::TaskLib
    attr_accessor :ignore_model_if, :name, :signature_root_dir

    def initialize(name = :rbs_rails, &block)
      super()

      @name = name

      block.call(self) if block

      setup_signature_root_dir!

      def_generate_rbs_for_controllers
      def_generate_rbs_for_models
      def_generate_rbs_for_path_helpers
      def_all
    end

    def def_all
      desc 'Run all tasks of rbs_rails'

      deps = [:"#{name}:generate_rbs_for_models", :"#{name}:generate_rbs_for_path_helpers"]
      task("#{name}:all": deps)
    end

    def def_generate_rbs_for_controllers
      desc 'Generate RBS files for Action Controllers'
      task("#{name}:generate_rbs_for_controllers": :environment) do
        require 'rbs_rails'

        Rails.application.eager_load!

        Rails.application.routes.routes.map do |route|
          controller_name = route.defaults[:controller].camelize + 'Controller'
          controller_name.constantize
        rescue NameError
          nil
        end

        ::ActionController::Base.descendants.each do |klass|
          next unless RbsRails::ActionController.user_defined_controller?(klass)

          path = signature_root_dir / "app/controllers/#{klass.name.underscore}.rbs"
          path.dirname.mkpath

          sig = RbsRails::ActionController.class_to_rbs(klass)
          path.write sig
        end
      end
    end

    def def_generate_rbs_for_models
      desc 'Generate RBS files for Active Record models'
      task("#{name}:generate_rbs_for_models": :environment) do
        require 'rbs_rails'

        Rails.application.eager_load!

        dep_builder = DependencyBuilder.new
        
        ::ActiveRecord::Base.descendants.each do |klass|
          next unless RbsRails::ActiveRecord.generatable?(klass)
          next if ignore_model_if&.call(klass)

          path = signature_root_dir / "app/models/#{klass.name.underscore}.rbs"
          path.dirname.mkpath

          sig = RbsRails::ActiveRecord.class_to_rbs(klass, dependencies: dep_builder.deps)
          path.write sig
          dep_builder.done << klass.name
        end

        if dep_rbs = dep_builder.build
          signature_root_dir.join('model_dependencies.rbs').write(dep_rbs)
        end
      end
    end

    def def_generate_rbs_for_path_helpers
      desc 'Generate RBS files for path helpers'
      task("#{name}:generate_rbs_for_path_helpers": :environment) do
        require 'rbs_rails'

        out_path = signature_root_dir.join 'path_helpers.rbs'
        rbs = RbsRails::PathHelpers.generate
        out_path.write rbs
      end
    end

    private def setup_signature_root_dir!
      @signature_root_dir ||= Rails.root / 'sig/rbs_rails'
      @signature_root_dir = Pathname(@signature_root_dir)
      @signature_root_dir.mkpath
    end
  end
end
