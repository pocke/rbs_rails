module RbsRails
  module ActiveRecord
    def self.class_to_rbs(klass, mode:)
      Generator.new(klass, mode: mode).generate
    end

    class Generator
      def initialize(klass, mode:)
        @klass = klass
        @mode = mode
      end

      def generate
        <<~RBS
          #{header}
          #{columns.indent(2)}
          end
        RBS
      end

      private def header
        case mode
        when :extension
          "extension #{klass.name} (RbsRails)"
        when :class
          "class #{klass.name} < #{klass.superclass.name}"
        else
          raise "unexpected mode: #{mode}"
        end
      end

      private def columns
        klass.columns.map do |col|
          "attr_accessor #{col.name} (): #{sql_type_to_class(col.type)}"
        end.join("\n")
      end

      private def sql_type_to_class(t)
        case t
        when :integer
          Integer.name
        when :string, :text, :uuid
          String.name
        when :datetime
          # TODO
          # ActiveSupport::TimeWithZone.name
          Time.name
        when :boolean
          "TrueClass | FalseClass"
        when :jsonb, :json
          "untyped"
        when :date
          # TODO
          # Date.name
          'untyped'
        else
          raise "unexpected: #{t.inspect}"
        end
      end

      private
      attr_reader :klass, :mode
    end
  end
end
