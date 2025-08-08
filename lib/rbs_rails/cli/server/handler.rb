require "webrick"

module RbsRails
  class CLI
    class Server
      class Handler
        attr_reader :config #: CLI::Configuration

        # @rbs config: CLI::Configuration
        def initialize(config) #: void
          @config = config
        end

        # @rbs env: Rack::env
        def call(env) #: Rack::response
          case env["REQUEST_METHOD"]
          when "POST"
            request = JSON.parse(env["rack.input"].read)
            do_POST(request["path"])
          else
            [405, { "Content-Type" => "text/plain" }, ["Method Not Allowed"]]
          end
        end

        # @rbs path: String?
        def do_POST(path) #: Rack::response
          path = regulate_path(path)
          if path.nil?
            [404, { "Content-Type" => "text/plain" }, ["Not Found"]]
          elsif path.extname != ".rb"
            [403, { "Content-Type" => "text/plain" }, ["Forbidden"]]
          else
            class_name = classify(path)
            if class_name.nil? || class_name.constantize.nil?
              [404, { "Content-Type" => "text/plain" }, ["Not Found"]]
            else
              generate_signature(class_name)
              [201, { "Content-Type" => "text/plain" }, ["Created"]]
            end
          end
        end

        private

        # @rbs path: String?
        def regulate_path(path) #: Pathname?
          return nil unless path

          pathname = Rails.root.join(path[1..]).realpath
          return nil unless pathname.to_s.start_with?(Rails.root.to_s + File::SEPARATOR)

          pathname.relative_path_from(Rails.root)
        rescue Errno::ENOENT
          nil
        end

        # @rbs path: Pathname
        def classify(path) #: String?
          # if the specified file is placed under autoload_paths...
          Rails.application.config.autoload_paths.each do |autoload_path|
            next unless path.to_s.start_with?(autoload_path.to_s + File::SEPARATOR)

            relative_path = path.relative_path_from(autoload_path)
            return relative_path.to_s.chomp(".rb").classify.constantize
          end

          # The file will be placed under app/*/ directories
          relative_path = path.to_s.sub(%r{^app/(.*?)/}, "")
          relative_path.chomp(".rb").classify
        rescue NameError
          nil
        end

        # @rbs path: String
        # @rbs class_name: String
        def generate_signature(class_name) #: void
          klass = class_name.constantize
          return unless klass < ::ActiveRecord::Base
          return if config.ignored_model?(klass)
          return unless ::RbsRails::ActiveRecord.generatable?(klass)

          original_path, _line = Object.const_source_location(klass.name) rescue nil

          rbs_relative_path = if original_path && Pathname.new(original_path).fnmatch?("#{Rails.root}/**")
                                Pathname.new(original_path)
                                        .relative_path_from(Rails.root)
                                        .sub_ext('.rbs')
                              else
                                "app/models/#{klass.name.underscore}.rbs"
                              end

          path = config.signature_root_dir / rbs_relative_path
          path.dirname.mkpath

          # TODO: We need to resolve the dependencies problem.
          sig = RbsRails::ActiveRecord.class_to_rbs(klass, dependencies: [])
          path.write sig
        end
      end
    end
  end
end
