require 'forwardable'
require 'singleton'

module RbsRails
  class CLI
    class Configuration
      include Singleton

      # @rbs!
      #   def self.instance: () -> Configuration
      #   def self.configure: () { (Configuration) -> void } -> void

      class << self
        extend Forwardable

        def_delegator :instance, :configure  # steep:ignore
      end

      # @rbs!
      #   @signature_root_dir: Pathname?
      #   @ignore_model_if: (^(singleton(ActiveRecord::Base)) -> bool)?

      attr_reader :check_db_migrations  #: bool

      def initialize #: void
        @signature_root_dir = nil
        @ignore_model_if = nil
        @check_db_migrations = true
      end

      # @rbs &block: (Configuration) -> void
      def configure(&block) #: void
        block.call(self)
      end

      def signature_root_dir #: Pathname
        @signature_root_dir || Rails.root.join("sig/rbs_rails")
      end

      # @rbs dir: String | Pathname
      def signature_root_dir=(dir) #: Pathname
        @signature_root_dir = case dir
                            when String
                              Pathname.new(dir)
                            when Pathname
                              dir
                            else
                              raise ArgumentError, "signature_root_dir must be String or Pathname"
                            end
      end

      # @rbs &block: (singleton(ActiveRecord::Base)) -> bool
      def ignore_model_if(&block) #: void
        @ignore_model_if = block
      end

      # @rbs klass: singleton(ActiveRecord::Base)
      def ignored_model?(klass) #: bool
        ignore_model_if = @ignore_model_if
        return false unless ignore_model_if

        ignore_model_if.call(klass)
      end
    end
  end
end
