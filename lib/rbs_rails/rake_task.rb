require 'rake'
require 'rake/tasklib'

module RbsRails
  class RakeTask < Rake::TaskLib
    # @rbs!
    #   interface _Filter
    #     def call: (Class) -> boolish
    #   end

    attr_accessor :ignore_model_if #: _Filter | nil
    attr_accessor :name #: Symbol
    attr_writer :signature_root_dir #: Pathname?

    # @rbs name: ::Symbol
    # @rbs &block: (RbsRails::RakeTask) -> void
    def initialize(name = :rbs_rails, &block) #: void
      super()

      @name = name
      @signature_root_dir = nil

      block.call(self) if block

      def_generate_rbs_for_models
      def_generate_rbs_for_path_helpers
      def_all
    end

    def def_all #: void
      desc 'Run all tasks of rbs_rails'
      task :"#{name}:all" do
        if signature_root_dir
          sh "rbs_rails", "all", "--signature-root-dir=#{signature_root_dir}"
        else
          sh "rbs_rails", "all"
        end
      end
    end

    def def_generate_rbs_for_models #: void
      desc 'Generate RBS files for Active Record models'
      task :"#{name}:generate_rbs_for_models" do
        warn "ignore_model_if is deprecated." if ignore_model_if

        if signature_root_dir
          sh "rbs_rails", "models", "--signature-root-dir=#{signature_root_dir}"
        else
          sh "rbs_rails", "models"
        end
      end
    end

    def def_generate_rbs_for_path_helpers #: void
      desc 'Generate RBS files for path helpers'
      task :"#{name}:generate_rbs_for_path_helpers" do
        if signature_root_dir
          sh "rbs_rails", "path_helpers", "--signature-root-dir=#{signature_root_dir}"
        else
          sh "rbs_rails", "path_helpers"
        end
      end
    end

    private def signature_root_dir #: Pathname?
      if path = @signature_root_dir
        Pathname(path)
      end
    end
  end
end
