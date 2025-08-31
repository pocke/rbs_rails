require "language_server-protocol"

require_relative "server/handler"
require_relative "server/transport"
require_relative "server/logger"

module RbsRails
  class CLI
    class Server
      include LanguageServer::Protocol
      include LanguageServer::Protocol::Constant

      attr_reader :config #: CLI::Configuration
      attr_reader :handler #: Server::Handler
      attr_reader :transport #: Transport
      attr_reader :logger #: Logger

      # @rbs config: CLI::Configuration
      # @rbs stdin: IO
      # @rbs stdout: IO
      def initialize(config, stdin: $stdin, stdout: $stdout) #: void
        @config = config
        @transport = Transport.new(stdin: stdin, stdout: stdout)
        @logger = Logger.new(@transport)
        @handler = Server::Handler.new(config, @logger)
      end

      def start #: void
        transport.read_requests do |request|
          begin
            handle_request(request)
          rescue StandardError => e
            transport.send_error_response(request, e)
          end
        end
      end

      private

      # @rbs request: Hash[Symbol, untyped]
      def handle_request(request) #: void
        case request[:method]
        when "initialize"
          handle_initialize(request)
        when "shutdown"
          handle_shutdown(request)
        when "textDocument/didSave"
          handler.handle_did_save(request)
        when "workspace/didChangeWatchedFiles"
          handler.handle_did_change_watched_files(request)
        when "exit"
          exit(0)
        else
          # Ignore unsupported requests
        end
      end

      # @rbs request: Hash[Symbol, untyped]
      def handle_initialize(request) #: void
        # Enable Rails app reloader manually
        Rails.env = "development"
        enable_zeitwerk_reloading

        send_initialize_result(request)
        send_register_capability_request
      end

      def send_initialize_result(request) #: void
        result = Interface::InitializeResult.new(
          capabilities: Interface::ServerCapabilities.new(
            text_document_sync: Interface::TextDocumentSyncOptions.new(
              save: true
            )
          )
        )

        transport.send_response(request[:id], result)
      end

      def send_register_capability_request #: void
        transport.send_request("client/registerCapability", {
          registrations: [
            {
              id: "watch-ruby-files",
              method: "workspace/didChangeWatchedFiles",
              registerOptions: {
                watchers: [
                  {
                    globPattern: "**/*.rb",
                    kind: WatchKind::CREATE | WatchKind::CHANGE | WatchKind::DELETE
                  }
                ]
              }
            }
          ]
        })
      end

      # @rbs request: Hash[Symbol, untyped]
      def handle_shutdown(request) #: void
        transport.send_response(request[:id], nil)
      end

      def enable_zeitwerk_reloading #: void
        Rails.autoloaders.main.enable_reloading
      end
    end
  end
end
