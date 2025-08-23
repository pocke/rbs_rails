require 'test_helper'

class ActiveRecordTest < Minitest::Test
  include Minitest::Hooks

  def before_all
    clean_test_signatures

    setup!
  end

  def test_type_check
    sh!('steep', 'check', chdir: app_dir)
  end

  def test_user_model_rbs_snapshot
    rbs_path = app_dir.join('sig/rbs_rails/app/models/user.rbs')
    expect_path = expectations_dir / 'user.rbs'
    # Code to re-generate the expectation files
    # expect_path.write rbs_path.read

    assert_equal expect_path.read, rbs_path.read
  end

  def test_blog_model_rbs_snapshot
    rbs_path = app_dir.join('sig/rbs_rails/packs/blogs/app/models/blog.rbs')
    expect_path = expectations_dir / 'blog.rbs'
    # Code to re-generate the expectation files
    # expect_path.write rbs_path.read

    assert_equal expect_path.read, rbs_path.read
  end

  def test_article_model_rbs_is_skipped
    rbs_path = app_dir.join('sig/rbs_rails/app/models/article.rbs')
    refute rbs_path.exist?
  end

  def test_external_library_model_rbs_generation
    rbs_path = app_dir.join('sig/rbs_rails/app/models/audited/audit.rbs')
    expect_path = expectations_dir / 'audited_audit.rbs'
    # Code to re-generate the expectation files
    # expect_path.write rbs_path.read

    assert_equal expect_path.read, rbs_path.read
  end

  def test_model_dependencies
    rbs_path = app_dir.join('sig/rbs_rails/model_dependencies.rbs')
    expect_path = expectations_dir / 'model_dependencies.rbs'
    # Code to re-generate the expectation files
    # expect_path.write rbs_path.read

    assert_equal expect_path.read, rbs_path.read
  end
end
