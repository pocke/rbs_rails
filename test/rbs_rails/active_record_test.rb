require 'test_helper'

class ActiveRecordTest < Minitest::Test
  def test_type_check_rails6
    clean_test_signatures

    setup!(rails6_app_dir)

    dir = rails6_app_dir
    sh!('steep', 'check', chdir: dir)
  end

  def test_user_model_rbs_snapshot_rails6
    clean_test_signatures

    setup!(rails6_app_dir)

    rbs_path = rails6_app_dir.join('sig/rbs_rails/app/models/user.rbs')
    expect_path = expectations_dir / 'user.rbs'
    # Code to re-generate the expectation files
    # expect_path.write rbs_path.read

    assert_equal expect_path.read, rbs_path.read
  end

  def test_user_model_rbs_snapshot_rails7
    clean_test_signatures

    setup!(rails7_app_dir)

    rbs_path = rails7_app_dir.join('sig/rbs_rails/app/models/user.rbs')
    expect_path = expectations_dir / 'user.rbs'
    # Code to re-generate the expectation files
    # expect_path.write rbs_path.read

    # TODO: Implement enum support for Rails7
    # assert_equal expect_path.read, rbs_path.read
  end

  def rails6_app_dir
    Pathname(__dir__).join('../rails6')
  end

  def rails7_app_dir
    Pathname(__dir__).join('../rails7')
  end

  def expectations_dir
    Pathname(__dir__).join('../expectations')
  end

  def setup!(dir)
    Bundler.with_unbundled_env do
      sh!('bundle', 'install', chdir: dir)
      sh!('bin/rake', 'db:create', 'db:schema:load', chdir: dir)
      sh!('bin/rake', 'rbs_rails:all', '--trace', chdir: dir)
    end
  end
end
