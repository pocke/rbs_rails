require 'test_helper'

class ActiveRecordTest < Minitest::Test
  def test_type_check
    clean_test_signatures

    setup!

    dir = app_dir
    sh!('steep', 'check', chdir: dir)
  end

  def test_user_model_rbs_snapshot
    clean_test_signatures

    setup!

    rbs_path = Pathname(app_dir).join('sig/rbs_rails/app/models/user.rbs')

    assert_equal <<~RBS, rbs_path.read
      class User < ApplicationRecord
        extend _ActiveRecord_Relation_ClassMethods[User, ActiveRecord_Relation]

        attr_accessor id(): Integer
        def id_changed?: () -> bool
        def id_change: () -> [ Integer?, Integer? ]
        def id_will_change!: () -> void
        def id_was: () -> Integer?
        def id_previously_changed?: () -> bool
        def id_previous_change: () -> Array[Integer?]?
        def id_previously_was: () -> Integer?
        def id_before_last_save: () -> Integer?
        def id_change_to_be_saved: () -> Array[Integer?]?
        def id_in_database: () -> Integer?
        def saved_change_to_id: () -> Array[Integer?]?
        def saved_change_to_id?: () -> bool
        def will_save_change_to_id?: () -> bool
        def restore_id!: () -> void
        def clear_id_change: () -> void

        attr_accessor name(): String
        def name_changed?: () -> bool
        def name_change: () -> [ String?, String? ]
        def name_will_change!: () -> void
        def name_was: () -> String?
        def name_previously_changed?: () -> bool
        def name_previous_change: () -> Array[String?]?
        def name_previously_was: () -> String?
        def name_before_last_save: () -> String?
        def name_change_to_be_saved: () -> Array[String?]?
        def name_in_database: () -> String?
        def saved_change_to_name: () -> Array[String?]?
        def saved_change_to_name?: () -> bool
        def will_save_change_to_name?: () -> bool
        def restore_name!: () -> void
        def clear_name_change: () -> void

        attr_accessor age(): Integer
        def age_changed?: () -> bool
        def age_change: () -> [ Integer?, Integer? ]
        def age_will_change!: () -> void
        def age_was: () -> Integer?
        def age_previously_changed?: () -> bool
        def age_previous_change: () -> Array[Integer?]?
        def age_previously_was: () -> Integer?
        def age_before_last_save: () -> Integer?
        def age_change_to_be_saved: () -> Array[Integer?]?
        def age_in_database: () -> Integer?
        def saved_change_to_age: () -> Array[Integer?]?
        def saved_change_to_age?: () -> bool
        def will_save_change_to_age?: () -> bool
        def restore_age!: () -> void
        def clear_age_change: () -> void

        attr_accessor created_at(): ActiveSupport::TimeWithZone
        def created_at_changed?: () -> bool
        def created_at_change: () -> [ ActiveSupport::TimeWithZone?, ActiveSupport::TimeWithZone? ]
        def created_at_will_change!: () -> void
        def created_at_was: () -> ActiveSupport::TimeWithZone?
        def created_at_previously_changed?: () -> bool
        def created_at_previous_change: () -> Array[ActiveSupport::TimeWithZone?]?
        def created_at_previously_was: () -> ActiveSupport::TimeWithZone?
        def created_at_before_last_save: () -> ActiveSupport::TimeWithZone?
        def created_at_change_to_be_saved: () -> Array[ActiveSupport::TimeWithZone?]?
        def created_at_in_database: () -> ActiveSupport::TimeWithZone?
        def saved_change_to_created_at: () -> Array[ActiveSupport::TimeWithZone?]?
        def saved_change_to_created_at?: () -> bool
        def will_save_change_to_created_at?: () -> bool
        def restore_created_at!: () -> void
        def clear_created_at_change: () -> void

        attr_accessor updated_at(): ActiveSupport::TimeWithZone
        def updated_at_changed?: () -> bool
        def updated_at_change: () -> [ ActiveSupport::TimeWithZone?, ActiveSupport::TimeWithZone? ]
        def updated_at_will_change!: () -> void
        def updated_at_was: () -> ActiveSupport::TimeWithZone?
        def updated_at_previously_changed?: () -> bool
        def updated_at_previous_change: () -> Array[ActiveSupport::TimeWithZone?]?
        def updated_at_previously_was: () -> ActiveSupport::TimeWithZone?
        def updated_at_before_last_save: () -> ActiveSupport::TimeWithZone?
        def updated_at_change_to_be_saved: () -> Array[ActiveSupport::TimeWithZone?]?
        def updated_at_in_database: () -> ActiveSupport::TimeWithZone?
        def saved_change_to_updated_at: () -> Array[ActiveSupport::TimeWithZone?]?
        def saved_change_to_updated_at?: () -> bool
        def will_save_change_to_updated_at?: () -> bool
        def restore_updated_at!: () -> void
        def clear_updated_at_change: () -> void

        def self.all_kind_args: (untyped a, ?untyped m, ?untyped n, *untyped rest, untyped x, ?k: untyped, **untyped kwrest) { (*untyped) -> untyped } -> ActiveRecord_Relation
        def self.no_arg: () -> ActiveRecord_Relation

        class ActiveRecord_Relation < ActiveRecord::Relation
          include _ActiveRecord_Relation[User]
          include Enumerable[User]

          def all_kind_args: (untyped a, ?untyped m, ?untyped n, *untyped rest, untyped x, ?k: untyped, **untyped kwrest) { (*untyped) -> untyped } -> ActiveRecord_Relation
          def no_arg: () -> ActiveRecord_Relation
        end

        class ActiveRecord_Associations_CollectionProxy < ActiveRecord::Associations::CollectionProxy
        end
      end
    RBS
  end

  def app_dir
    File.expand_path('../app', __dir__) 
  end

  def setup!
    dir = app_dir

    Bundler.with_unbundled_env do
      sh!('bundle', 'install', chdir: dir)
      sh!('bin/rake', 'db:create', 'db:schema:load', chdir: dir)
      sh!('bin/rake', 'rbs_rails:all', chdir: dir)
    end
  end
end
