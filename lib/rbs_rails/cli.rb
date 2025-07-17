require "optparse"

module RbsRails
  class CLI
    attr_reader :options #: Hash[Symbol, untyped]

    def initialize #: void
      @options = {}
    end

    # @rbs argv: Array[String]
    def run(argv) #: Integer
      parser = create_option_parser

      begin
        args = parser.parse(argv)
        subcommand = args.shift || "help"

        case subcommand
        when "help"
          $stdout.puts parser.help
          0
        when "version"
          $stdout.puts "rbs_rails #{RbsRails::VERSION}"
          0
        when "all"
          load_application
          generate_models
          generate_path_helpers
          0
        when "models"
          load_application
          generate_models
          0
        when "path_helpers"
          load_application
          generate_path_helpers
          0
        else
          $stdout.puts "Unknown command: #{subcommand}"
          $stdout.puts parser.help
          1
        end
      rescue OptionParser::InvalidOption => e
        $stderr.puts "Error: #{e.message}"
        $stdout.puts parser.help
        1
      end
    rescue StandardError => e
      $stderr.puts "Error: #{e.message}"
      1
    end

    private

    def load_application #: void
      require_relative "#{Dir.getwd}/config/application"

      install_hooks

      Rails.application.initialize!
    end

    def install_hooks #: void
      # Load inspectors.  This is necessary to load earlier than Rails application.
      require 'rbs_rails/active_record/enum'
    end

    def generate_models #: void
      Rails.application.eager_load!

      dep_builder = DependencyBuilder.new

      ::ActiveRecord::Base.descendants.each do |klass|
        generate_single_model(klass, dep_builder)
      rescue => e
        puts "Error generating RBS for #{klass.name} model"
        raise e
      end

      if dep_rbs = dep_builder.build
        signature_root_dir.join('model_dependencies.rbs').write(dep_rbs)
      end
    end

    # @rbs klass: singleton(ActiveRecord::Base)
    # @rbs dep_builder: DependencyBuilder
    def generate_single_model(klass, dep_builder) #: bool
      # next if ignore_model_if&.call(klass)
      return false unless RbsRails::ActiveRecord.generatable?(klass)

      original_path, _line = Object.const_source_location(klass.name) rescue nil

      rbs_relative_path = if original_path && Pathname.new(original_path).fnmatch?("#{Rails.root}/**")
                            Pathname.new(original_path)
                                    .relative_path_from(Rails.root)
                                    .sub_ext('.rbs')
                          else
                            "app/models/#{klass.name.underscore}.rbs"
                          end

      path = signature_root_dir / rbs_relative_path
      path.dirname.mkpath

      sig = RbsRails::ActiveRecord.class_to_rbs(klass, dependencies: dep_builder.deps)
      path.write sig
      dep_builder.done << klass.name

      true
    end

    def generate_path_helpers #: void
      path = signature_root_dir.join 'path_helpers.rbs'
      path.dirname.mkpath

      sig = RbsRails::PathHelpers.generate
      path.write sig
    end

    def create_option_parser #: OptionParser
      OptionParser.new do |opts|
        opts.banner = <<~BANNER
          Usage: rbs_rails [command] [options]

          Commands:
                  help           Show this help message
                  version        Show version
                  all            Generate all RBS files
                  models         Generate RBS files for models
                  path_helpers   Generate RBS for Rails path helpers

          Options:
        BANNER

        opts.on("--signature-root-dir=DIR", "Specify the root directory for RBS signatures") do |dir|
          @options[:signature_root_dir] = Pathname.new(dir)
        end
      end
    end

    def signature_root_dir #: Pathname
      @options[:signature_root_dir] || Rails.root.join("sig/rbs_rails")
    end
  end
end
