require 'test_helper'

class PostgreSQLIntegrationTest < Minitest::Test
  include Minitest::Hooks

  def before_all
    return unless ENV['PGHOST']

    clean_pg_test_signatures
    pg_setup!
  end

  def setup
    skip 'Set PGHOST to run PostgreSQL integration tests' unless ENV['PGHOST']
  end

  def test_post_model_rbs_snapshot
    expect_path = expectations_dir / 'pg' / 'post.rbs'
    skip 'Expectation file not found. Run with the regeneration comment uncommented.' unless expect_path.exist?

    # To regenerate:
    # expect_path.parent.mkpath
    # expect_path.write post_rbs_content
    assert_equal expect_path.read, post_rbs_content
  end

  private

  def post_rbs_content
    pg_app_dir.join('sig/rbs_rails/app/models/post.rbs').read
  end
end
