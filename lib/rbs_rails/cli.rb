require "thor"
require "rbs_rails/cli/configuration"

module RbsRails
  # @rbs &block: (CLI::Configuration) -> void
  def self.configure(&block) #: void
    CLI::Configuration.configure(&block)
  end

  class CLI < Thor
    class_option :signature_root_dir, type: :string, banner: "DIR",
                 desc: "Specify the root directory for RBS signatures"
    class_option :config, type: :string, banner: "FILE",
                 desc: "Load configuration from FILE"

    desc "all", "Generate all RBS files"
    def all #: void
      apply_options
      load_application
      load_config
      generate_models
      generate_path_helpers
    end

    desc "models", "Generate RBS files for models"
    def models #: void
      apply_options
      load_application
      load_config
      generate_models
    end

    desc "path_helpers", "Generate RBS for Rails path helpers"
    def path_helpers #: void
      apply_options
      load_application
      load_config
      generate_path_helpers
    end

    desc "version", "Show version"
    def version #: void
      puts "rbs_rails #{RbsRails::VERSION}"
    end

    def self.exit_on_failure? #: bool
      true
    end

    private

    def apply_options #: void
      rbs_config.signature_root_dir = Pathname.new(options[:signature_root_dir]) if options[:signature_root_dir]
    end

    def rbs_config #: Configuration
      Configuration.instance
    end

    def load_config #: void
      config_file = options[:config]
      if config_file
        load config_file
      else
        if File.exist?(".rbs_rails.rb")
          load ".rbs_rails.rb"
        elsif Rails.root.join("config/rbs_rails.rb").exist?
          load Rails.root.join("config/rbs_rails.rb").to_s
        end
      end
    end

    def load_application #: void
      require_relative "#{Dir.getwd}/config/application"

      install_hooks

      Rails.application.initialize!
    rescue LoadError => e
      raise "Failed to load Rails application: #{e.message}"
    end

    def install_hooks #: void
      # Load inspectors.  This is necessary to load earlier than Rails application.
      require 'rbs_rails/active_record/enum'
    end

    def generate_models #: void
      check_db_migrations!
      Rails.application.eager_load!

      ::ActiveRecord::Base.descendants.each do |klass|
        generate_single_model(klass)
      rescue => e
        puts "Error generating RBS for #{klass.name} model"
        raise e
      end
    end

    # Raise an error if database is not migrated to the latest version
    def check_db_migrations! #: void
      return unless rbs_config.check_db_migrations

      if ::ActiveRecord::Migration.respond_to? :check_all_pending!
        # Rails 7.1 or later
        ::ActiveRecord::Migration.check_all_pending!  # steep:ignore NoMethod
      else
        ::ActiveRecord::Migration.check_pending!
      end
    end

    # @rbs klass: singleton(ActiveRecord::Base)
    def generate_single_model(klass) #: bool
      return false if rbs_config.ignored_model?(klass)
      return false unless RbsRails::ActiveRecord.generatable?(klass)

      original_path, _line = Object.const_source_location(klass.name) rescue nil

      rbs_relative_path = if original_path && Pathname.new(original_path).fnmatch?("#{Rails.root}/**")
                            Pathname.new(original_path)
                                    .relative_path_from(Rails.root)
                                    .sub_ext('.rbs')
                          else
                            "app/models/#{klass.name.underscore}.rbs"
                          end

      path = rbs_config.signature_root_dir / rbs_relative_path
      path.dirname.mkpath

      sig = RbsRails::ActiveRecord.class_to_rbs(klass)
      Util::FileWriter.new(path).write sig

      true
    end

    def generate_path_helpers #: void
      path = rbs_config.signature_root_dir.join 'path_helpers.rbs'
      path.dirname.mkpath

      sig = RbsRails::PathHelpers.generate
      Util::FileWriter.new(path).write sig
    end
  end
end
