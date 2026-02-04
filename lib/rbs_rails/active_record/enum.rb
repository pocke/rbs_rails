require 'active_support/lazy_load_hooks'

module RbsRails
  module ActiveRecord
    module Enum
      IGNORED_ENUM_KEYS = %i[prefix suffix default scopes]

      # @rbs!
      #   type definitions = Hash[Symbol, Array[Symbol] | Hash[Symbol, untyped]]
      #   type options = Hash[Symbol, untyped]
      #   type enum_definitions = Array[[definitions, options]]
      #
      #   @enum_definitions: enum_definitions

      def enum(*args, **options) #: untyped
        result = super  # steep:ignore

        name, values = args #: [Symbol, Array[Symbol]?]
        if values
          # Enum definitions are passed via array argument
          #   ex. enum :status, [:temporary, :accepted]
          definitions = { name => values }
        else
          # Enum definitions are passed via keyword arguments
          #   ex. enum :status, temporary: 1, accepted: 2
          values = options.slice!(*IGNORED_ENUM_KEYS)
          definitions = { name => values }
        end

        @enum_definitions ||= [] #: enum_definitions
        @enum_definitions&.append([definitions, options])

        result
      end

      def enum_definitions #: Array[[Symbol, String]]
        @enum_definitions&.flat_map do |(definitions, options)|
          definitions.flat_map do |name, values|
            labels = case values
                     when Array
                       values
                     when Hash
                       values.keys
                     end
            labels.map do |label|
              [name, enum_method_name(name, label, options)] #: [Symbol, String]
            end
          end
        end.to_a
      end

      # @rbs name: Symbol
      # @rbs label: Symbol
      # @rbs options: Hash[Symbol, untyped]
      private def enum_method_name(name, label, options) #: String
        enum_prefix = options[:_prefix] || options[:prefix]
        enum_suffix = options[:_suffix] || options[:suffix]

        if enum_prefix == true
          prefix = "#{name}_"
        elsif enum_prefix
          prefix = "#{enum_prefix}_"
        end
        if enum_suffix == true
          suffix = "_#{name}"
        elsif enum_suffix
          suffix = "_#{enum_suffix}"
        end

        enum_method_name = "#{prefix}#{label}#{suffix}"

        # Make enum_method_name friendly
        # refs: https://github.com/rails/rails/blob/v8.0.0/activerecord/lib/active_record/enum.rb#L270
        enum_method_name.gsub(/[\W&&[:ascii:]]+/, "_")
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  # @type self: singleton(ActiveRecord::Base)
  extend RbsRails::ActiveRecord::Enum
end
