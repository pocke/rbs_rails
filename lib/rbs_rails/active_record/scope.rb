require 'active_support/lazy_load_hooks'

module RbsRails
  module ActiveRecord
    module Scope
      attr_accessor :scope_definitions #: Hash[Symbol, untyped]?

      # @rbs name: Symbol
      # @rbs body: untyped
      # @rbs &block: (?) -> untyped
      def scope(name, body, &block) #: void
        super  # steep:ignore

        @scope_definitions ||= {} #: Hash[Symbol, untyped]
        @scope_definitions[name] = body # steep:ignore
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  # @type self: singleton(ActiveRecord::Base)
  extend RbsRails::ActiveRecord::Scope
end
