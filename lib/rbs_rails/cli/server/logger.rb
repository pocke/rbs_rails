module RbsRails
  class CLI
    class Server
      class Logger
        include LanguageServer::Protocol::Constant

        attr_reader :transport #: Transport

        # @rbs transport: Transport
        def initialize(transport) #: void
          @transport = transport
        end

        # @rbs message: String
        def info(message) #: void
          transport.send_notification('window/logMessage', {
            type: MessageType::INFO,
            message: message
          })
        end

        # @rbs message: String
        def error(message) #: void
          transport.send_notification('window/showMessage', {
            type: MessageType::ERROR,
            message: message
          })
        end

        # @rbs message: String
        def warn(message) #: void
          transport.send_notification('window/logMessage', {
            type: MessageType::WARNING,
            message: message
          })
        end

        # @rbs message: String
        def debug(message) #: void
          transport.send_notification('window/logMessage', {
            type: MessageType::LOG,
            message: message
          })
        end
      end
    end
  end
end
