module RbsRails
  class CLI
    class Server
      class Transport
        include LanguageServer::Protocol
        include LanguageServer::Protocol::Constant

        attr_reader :reader #: LanguageServer::Protocol::Transport::Io::Reader
        attr_reader :writer #: LanguageServer::Protocol::Transport::Io::Writer

        # @rbs stdin: IO
        # @rbs stdout: IO
        def initialize(stdin: $stdin, stdout: $stdout) #: void
          @writer = LanguageServer::Protocol::Transport::Io::Writer.new(stdout)
          @reader = LanguageServer::Protocol::Transport::Io::Reader.new(stdin)
        end

        # @rbs id: String
        # @rbs result: untyped
        def send_response(id, result) #: void
          response = {
            jsonrpc: "2.0",
            id: id,
            result: result
          }
          writer.write(response)
        end

        # @rbs request: Hash[Symbol, untyped]
        # @rbs error: Exception
        def send_error_response(request, error) #: void
          response = {
            jsonrpc: "2.0",
            id: request[:id],
            error: {
              code: ErrorCodes::INTERNAL_ERROR,
              message: error.message
            }
          }
          writer.write(response)
        end

        # @rbs method: String
        # @rbs params: Hash[Symbol, untyped]
        def send_request(method, params) #: void
          request = {
            jsonrpc: "2.0",
            id: Time.now.to_f.to_s,
            method: method,
            params: params
          }
          writer.write(request)
        end

        # @rbs method: String
        # @rbs params: Hash[Symbol, untyped]
        def send_notification(method, params) #: void
          notification = {
            jsonrpc: "2.0",
            method: method,
            params: params
          }
          writer.write(notification)
        end

        # @rbs &block: (Hash[Symbol, untyped]) -> void
        def read_requests(&block) #: untyped
          reader.read(&block)
        end
      end
    end
  end
end
