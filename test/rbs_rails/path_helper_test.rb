require 'test_helper'

class PathHelperTest < Minitest::Test
  include Minitest::Hooks

  def before_all
    clean_test_signatures

    setup!
  end

  def test_type_check
    sh!('steep', 'check', chdir: app_dir)
  end

  def test_user_model_rbs_snapshot
    rbs_path = app_dir.join('sig/rbs_rails/path_helpers.rbs')
    expect_path = expectations_dir / 'path_helpers.rbs'
    # Code to re-generate the expectation files
    # expect_path.write rbs_path.read

    assert_equal expect_path.read, rbs_path.read
  end
end
