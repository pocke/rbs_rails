require 'rake'
require 'rake/tasklib'

module RbsRails
  class RakeTask < Rake::TaskLib
    attr_accessor :ignore_model_if, :name

    def initialize(name = :rbs_rails, &block)
      super()

      @name = name

      block.call(self) if block

      def_copy_signature_files
      def_generate_rbs_for_models
      def_generate_rbs_for_path_helpers
      def_all
    end

    def def_all
      desc 'Run all tasks of rbs_rails'

      deps = [:"#{name}:copy_signature_files", :"#{name}:generate_rbs_for_models", :"#{name}:generate_rbs_for_path_helpers"]
      task("#{name}:all": deps)
    end

    def def_copy_signature_files
      desc 'Copy RBS files for rbs_rails'
      task("#{name}:copy_signature_files": :environment) do
        require 'rbs_rails'

        to = Rails.root.join('sig/rbs_rails/')
        to.mkpath unless to.exist?
        RbsRails.copy_signatures(to: to)
      end
    end

    def def_generate_rbs_for_models
      desc 'Generate RBS files for Active Record models'
      task("#{name}:generate_rbs_for_models": :environment) do
        require 'rbs_rails'

        out_dir = Rails.root / 'sig'
        out_dir.mkdir unless out_dir.exist?

        Rails.application.eager_load!

        ::ActiveRecord::Base.descendants.each do |klass|
          next if klass.abstract_class?
          next if ignore_model_if && ignore_model_if.call(klass)

          path = out_dir / "app/models/#{klass.name.underscore}.rbs"
          FileUtils.mkdir_p(path.dirname)

          sig = RbsRails::ActiveRecord.class_to_rbs(klass)
          path.write sig
        end
      end
    end

    def def_generate_rbs_for_path_helpers
      desc 'Generate RBS files for path helpers'
      task("#{name}:generate_rbs_for_path_helpers": :environment) do
        require 'rbs_rails'

        out_path = Rails.root.join 'sig/path_helpers.rbs'
        rbs = RbsRails::PathHelpers.generate
        out_path.write rbs
      end
    end
  end
end
