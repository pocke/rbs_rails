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
        [
          klass_decl,
          relation_decl,
          collection_proxy_decl,
        ].join("\n")
      end

      private def klass_decl
        <<~RBS
          #{header}
            extend _ActiveRecord_Relation_ClassMethods[#{klass.name}, #{relation_class_name}]

          #{columns.indent(2)}
          #{associations.indent(2)}
          end
        RBS
      end

      private def relation_decl
        <<~RBS
          class #{relation_class_name} < ActiveRecord::Relation
            include _ActiveRecord_Relation[#{klass.name}]
            include Enumerable[#{klass.name}, self]
          end
        RBS
      end

      private def collection_proxy_decl
        <<~RBS
          class #{klass.name}::ActiveRecord_Associations_CollectionProxy < ActiveRecord::Associations::CollectionProxy
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

      private def associations
        [
          has_many,
          has_one,
          belongs_to,
        ].join("\n")
      end

      private def has_many
        klass.reflect_on_all_associations(:has_many).map do |a|
          "def #{a.name}: () -> #{a.klass.name}::ActiveRecord_Associations_CollectionProxy"
        end.join("\n")
      end

      private def has_one
        klass.reflect_on_all_associations(:has_one).map do |a|
          type = a.polymorphic? ? 'untyped' : a.klass.name
          "def #{a.name}: () -> #{type}"
        end.join("\n")
      end

      private def belongs_to
        klass.reflect_on_all_associations(:belongs_to).map do |a|
          type = a.polymorphic? ? 'untyped' : a.klass.name
          "def #{a.name}: () -> #{type}"
        end.join("\n")
      end

      private def relation_class_name
        "#{klass.name}::ActiveRecord_Relation"
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
