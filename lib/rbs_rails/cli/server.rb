require "rackup"
require "webrick"

require_relative "server/handler"

module RbsRails
  class CLI
    class Server
      attr_reader :config #: CLI::Configuration

      # @rbs config: CLI::Configuration
      def initialize(config) #: void
        @config = config
      end

      def start
        # Set the Rails environment to development
        Rails.env = "development"
        enable_zeitwerk_reloading

        puts "Starting rbs_rails server on #{config.host}:#{config.port}"
        rack_app = build_rack_app
        Rackup::Handler::WEBrick.run(rack_app, Host: config.host, Port: config.port)

        # Signal.trap(:INT) { server.shutdown }

        # server.start
      rescue Interrupt
        puts "Server stopped."
      end

      private

      def enable_zeitwerk_reloading #: void
        Rails.autoloaders.main.enable_reloading
      end

      def build_rack_app
        handler = Server::Handler.new(config)
        Rack::Builder.new do
          # @type self: Rack::Builder
          use ActionDispatch::Reloader, Rails.application.reloader
          run handler
        end
      end
    end
  end
end
