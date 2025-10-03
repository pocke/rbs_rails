module RbsRails
  module Util
    # To avoid unnecessary type reloading by type checkers and other utilities,
    # FileWriter modifies the target file only if its content has been changed.
    class FileWriter
      attr_reader :path  #: Pathname

      # @rbs path: Pathname
      def initialize(path) #: void
        @path = path
      end

      def write(content) #: void
        original_content = path.read rescue nil

        if original_content != content
          path.write(content)
        end
      end
    end
  end
end
