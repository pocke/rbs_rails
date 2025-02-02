require 'active_support/lazy_load_hooks'

module RbsRails
  module ActiveRecord
    module Enum
      IGNORED_ENUM_KEYS = %i[_prefix _suffix _default _scopes]

      def enum(*args, **options)
        super  # steep:ignore

        if args.empty?
          definitions = options.slice!(*IGNORED_ENUM_KEYS)
          @enum_definitions ||= []
          @enum_definitions&.append([definitions, options])
        end
      end

      def enum_definitions
        @enum_definitions&.flat_map do |(definitions, options)|
          definitions.flat_map do |name, values|
            values.map do |label, value|
              [name, enum_method_name(name, label, options)]
            end
          end
        end.to_a
      end

      private def enum_method_name(name, label, options)
        enum_prefix = options[:_prefix]
        enum_suffix = options[:_suffix]

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

        "#{prefix}#{label}#{suffix}"
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  # @type self: singleton(ActiveRecord::Base)
  extend RbsRails::ActiveRecord::Enum
end
