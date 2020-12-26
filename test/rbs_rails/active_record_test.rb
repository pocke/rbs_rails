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

    rbs_path = Pathname(app_dir).join('sig/app/models/user.rbs')

    assert_equal <<~RBS, rbs_path.read
      class User < ApplicationRecord
        extend _ActiveRecord_Relation_ClassMethods[User, User::ActiveRecord_Relation]

        attr_accessor id (): Integer
        def id_changed?: () -> bool
        def id_change: () -> [Integer?, Integer?]
        def id_will_change!: () -> void
        def id_was: () -> Integer?
        def id_previously_changed?: () -> bool
        def id_previous_change: () -> Array[Integer?]?
        def id_previously_was: () -> Integer?
        def restore_id!: () -> void
        def clear_id_change: () -> void

        attr_accessor name (): String
        def name_changed?: () -> bool
        def name_change: () -> [String?, String?]
        def name_will_change!: () -> void
        def name_was: () -> String?
        def name_previously_changed?: () -> bool
        def name_previous_change: () -> Array[String?]?
        def name_previously_was: () -> String?
        def restore_name!: () -> void
        def clear_name_change: () -> void

        attr_accessor age (): Integer
        def age_changed?: () -> bool
        def age_change: () -> [Integer?, Integer?]
        def age_will_change!: () -> void
        def age_was: () -> Integer?
        def age_previously_changed?: () -> bool
        def age_previous_change: () -> Array[Integer?]?
        def age_previously_was: () -> Integer?
        def restore_age!: () -> void
        def clear_age_change: () -> void

        attr_accessor created_at (): ActiveSupport::TimeWithZone
        def created_at_changed?: () -> bool
        def created_at_change: () -> [ActiveSupport::TimeWithZone?, ActiveSupport::TimeWithZone?]
        def created_at_will_change!: () -> void
        def created_at_was: () -> ActiveSupport::TimeWithZone?
        def created_at_previously_changed?: () -> bool
        def created_at_previous_change: () -> Array[ActiveSupport::TimeWithZone?]?
        def created_at_previously_was: () -> ActiveSupport::TimeWithZone?
        def restore_created_at!: () -> void
        def clear_created_at_change: () -> void

        attr_accessor updated_at (): ActiveSupport::TimeWithZone
        def updated_at_changed?: () -> bool
        def updated_at_change: () -> [ActiveSupport::TimeWithZone?, ActiveSupport::TimeWithZone?]
        def updated_at_will_change!: () -> void
        def updated_at_was: () -> ActiveSupport::TimeWithZone?
        def updated_at_previously_changed?: () -> bool
        def updated_at_previous_change: () -> Array[ActiveSupport::TimeWithZone?]?
        def updated_at_previously_was: () -> ActiveSupport::TimeWithZone?
        def restore_updated_at!: () -> void
        def clear_updated_at_change: () -> void







      end

      class User::ActiveRecord_Relation < ActiveRecord::Relation
        include _ActiveRecord_Relation[User]
        include Enumerable[User]


      end

      class User::ActiveRecord_Associations_CollectionProxy < ActiveRecord::Associations::CollectionProxy
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
