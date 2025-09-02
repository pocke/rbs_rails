require 'test_helper'
require 'active_record'

class EnumTest < Minitest::Test
  def test_rails4_alias_attribute_enum
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      alias_attribute :alias_status, :status
      enum alias_status: [:temporary, :accepted], _default: :temporary
    end

    assert_equal [[:alias_status, "temporary"], [:alias_status, "accepted"]], model.enum_definitions
  end

  def test_rails4_array_enum
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      enum status: [:temporary, :accepted], _default: :temporary
    end

    assert_equal [[:status, "temporary"], [:status, "accepted"]], model.enum_definitions
  end

  def test_rails4_hash_enum
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      enum status: {
        temporary: 1,
        accepted: 2,
      }, _default: :temporary
    end

    assert_equal [[:status, "temporary"], [:status, "accepted"]], model.enum_definitions
  end

  def test_rails4_enum_has_prefix
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      enum status: {
        temporary: 1,
        accepted: 2,
      }, _prefix: true
    end

    assert_equal [[:status, "status_temporary"], [:status, "status_accepted"]], model.enum_definitions
  end

  def test_rails4_enum_named_prefix
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      enum status: {
        temporary: 1,
        accepted: 2,
      }, _prefix: "prefix"
    end

    assert_equal [[:status, "prefix_temporary"], [:status, "prefix_accepted"]], model.enum_definitions
  end

  def test_rails4_enum_has_suffix
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      enum status: {
        temporary: 1,
        accepted: 2,
      }, _suffix: true
    end

    assert_equal [[:status, "temporary_status"], [:status, "accepted_status"]], model.enum_definitions
  end

  def test_rails4_enum_named_suffix
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      enum status: {
        temporary: 1,
        accepted: 2,
      }, _suffix: "suffix"
    end

    assert_equal [[:status, "temporary_suffix"], [:status, "accepted_suffix"]], model.enum_definitions
  end

  def test_rails4_unfriendly_enum
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      enum timezone: {
        'America/Los_Angeles': 'America/Los_Angeles',
        'America/Denver': 'America/Denver',
        'America/Chicago': 'America/Chicago',
        'America/New_York': 'America/New_York'
      }
    end

    assert_equal [[:timezone, "America_Los_Angeles"],
                  [:timezone, "America_Denver"],
                  [:timezone, "America_Chicago"],
                  [:timezone, "America_New_York"]],
                 model.enum_definitions
  end

  def test_rails7_alias_attribute_enum
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      alias_attribute :alias_status, :status
      enum :alias_status, [:temporary, :accepted], default: :temporary
    end

    assert_equal [[:alias_status, "temporary"], [:alias_status, "accepted"]], model.enum_definitions
  end

  def test_rails7_array_enum
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      enum :status, [:temporary, :accepted], default: :temporary
    end

    assert_equal [[:status, "temporary"], [:status, "accepted"]], model.enum_definitions
  end

  def test_rails7_kwargs_enum
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      enum :status, temporary: 1, accepted: 2, default: :temporary
    end

    assert_equal [[:status, "temporary"], [:status, "accepted"]], model.enum_definitions
  end

  def test_rails7_enum_has_prefix
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      enum :status, [:temporary, :accepted], prefix: true
    end

    assert_equal [[:status, "status_temporary"], [:status, "status_accepted"]], model.enum_definitions
  end

  def test_rails7_enum_named_prefix
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      enum :status, [:temporary, :accepted], prefix: "prefix"
    end

    assert_equal [[:status, "prefix_temporary"], [:status, "prefix_accepted"]], model.enum_definitions
  end

  def test_rails7_enum_has_suffix
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      enum :status, [:temporary, :accepted], suffix: true
    end

    assert_equal [[:status, "temporary_status"], [:status, "accepted_status"]], model.enum_definitions
  end

  def test_rails7_enum_named_suffix
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      enum :status, [:temporary, :accepted], suffix: "suffix"
    end

    assert_equal [[:status, "temporary_suffix"], [:status, "accepted_suffix"]], model.enum_definitions
  end

  def test_rails7_unfriendly_enum
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Enum

      enum :timezone, {
        'America/Los_Angeles': 'America/Los_Angeles',
        'America/Denver': 'America/Denver',
        'America/Chicago': 'America/Chicago',
        'America/New_York': 'America/New_York'
      }
    end

    assert_equal [[:timezone, "America_Los_Angeles"],
                  [:timezone, "America_Denver"],
                  [:timezone, "America_Chicago"],
                  [:timezone, "America_New_York"]],
                 model.enum_definitions
  end
end
