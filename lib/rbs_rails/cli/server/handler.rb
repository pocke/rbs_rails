require_relative "debouncer"

module RbsRails
  class CLI
    class Server
      class Handler
        include Debouncer
        include LanguageServer::Protocol::Constant

        attr_reader :config #: CLI::Configuration
        attr_reader :logger #: Logger

        # @rbs config: CLI::Configuration
        # @rbs logger: Logger
        def initialize(config, logger) #: void
          @config = config
          @logger = logger
        end

        # @rbs request: Hash[Symbol, untyped]
        def handle_did_save(request) #: void
          params = request[:params]
          uri = params[:textDocument][:uri]

          return if should_skip_generation?(uri)

          Rails.application.reloader.wrap do
            generate_signature(uri)
          end
        rescue Exception => e
          logger.error("Failed to generate RBS: #{e.message}")
        end

        # @rbs request: Hash[Symbol, untyped]
        def handle_did_change_watched_files(request) #: void
          params = request[:params]
          changes = params[:changes] || []

          # Filter out changes that were generated recently (see Debouncer)
          changes = changes.reject { should_skip_generation?(_1[:uri]) }
          return if changes.empty?

          Rails.application.reloader.wrap do
            changes.each do |change|
              uri = change[:uri]
              type = change[:type]

              case type
              when FileChangeType::CREATED, FileChangeType::CHANGED
                generate_signature(uri)
              when FileChangeType::DELETED
                delete_signature(uri)
              end
            end
          end
        end

        private

        # @rbs uri: String
        def generate_signature(uri) #: void
          begin
            path = uri_to_path(uri)
            return if path.nil?

            case path.to_s
            when "db/schema.rb"
              generate_all_model_signatures
              logger.info("Generated RBS for all models")
            when %r{^config/(routes\.rb|routes/.*\.rb)$}
              generate_path_helpers_signature
              logger.info("Generated RBS for path helpers")
            when %r{\.rb$}
              klass = constantize(path)
              return unless klass

              generate_signature0(path, klass)
              logger.info("Generated RBS for #{File.basename(uri)}")
            end
          rescue => e
            logger.error("Error generating signature for #{path}: #{e.message}")
          end
        end

        def generate_all_model_signatures #: void
          Rails.application.eager_load!
          ::ActiveRecord::Base.descendants.each do |klass|
            original_path, _line = Object.const_source_location(klass.name) rescue nil

            path = if original_path && Pathname.new(original_path).fnmatch?("#{Rails.root}/**")
                     Pathname.new(original_path)
                       .relative_path_from(Rails.root)
                       .sub_ext('.rb')
                   else
                     Pathname.new("app/models/#{klass.name.underscore}.rb")
                   end
            generate_signature0(path, klass)
          end
        end

        def generate_path_helpers_signature #: void
          path = config.signature_root_dir.join 'path_helpers.rbs'
          path.dirname.mkpath

          sig = RbsRails::PathHelpers.generate
          Util::FileWriter.new(rbs_path).write sig
        end

        # @rbs path: Pathname
        # @rbs klass: Class
        def generate_signature0(path, klass) #: void
          return unless klass < ::ActiveRecord::Base
          return if config.ignored_model?(klass)
          return unless ::RbsRails::ActiveRecord.generatable?(klass)

          rbs_path = config.signature_root_dir / path.sub_ext('.rbs')
          rbs_path.dirname.mkpath

          sig = RbsRails::ActiveRecord.class_to_rbs(klass)
          Util::FileWriter.new(rbs_path).write sig
        end

        # @rbs uri: String
        def delete_signature(uri) #: void
          path = uri_to_path(uri)
          return false if path.nil?
          return false unless path.extname == '.rb'

          rbs_path = config.signature_root_dir / path.sub_ext('.rbs')
          if rbs_path.exist?
            rbs_path.delete
            logger.info("Deleted RBS for #{File.basename(uri)}")
          end
        rescue => e
          puts "Error deleting signature for #{path}: #{e.message}", $stderr
        end

        # @rbs uri: String
        def uri_to_path(uri) #: Pathname?
          path = Pathname.new(uri.sub(/^file:\/\//, ''))

          # Ignore if the given path is not under Rails.root
          return nil unless path.to_s.start_with?(Rails.root.to_s + File::SEPARATOR)

          path.relative_path_from(Rails.root)
        end

        # @rbs path: Pathname
        def constantize(path) #: Class?
          # If the specified file is placed under autoload_paths...
          Rails.application.config.autoload_paths.each do |autoload_path|
            next unless path.to_s.start_with?(autoload_path.to_s + File::SEPARATOR)

            relative_path = path.relative_path_from(autoload_path)
            return relative_path.to_s.chomp(".rb").classify.constantize
          end

          # If not, the file must be placed under app/*/ directories
          relative_path = path.to_s.sub(%r{^app/(.*?)/}, "")
          relative_path.chomp(".rb").classify.constantize
        rescue NameError
          nil
        end
      end
    end
  end
end
