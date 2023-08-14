require 'test_helper'

class ActiveRecordTest < Minitest::Test
  def test_type_check
    clean_test_signatures

    setup!(rails6_app_dir)

    dir = rails6_app_dir
    sh!('steep', 'check', chdir: dir)
  end

  def test_user_model_rbs_snapshot
    clean_test_signatures

    setup!(rails6_app_dir)

    rbs_path = rails6_app_dir.join('sig/rbs_rails/app/models/user.rbs')
    expect_path = expectations_dir / 'user.rbs'
    # Code to re-generate the expectation files
    # expect_path.write rbs_path.read

    assert_equal expect_path.read, rbs_path.read
  end

  def rails6_app_dir
    Pathname(__dir__).join('../rails6')
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
