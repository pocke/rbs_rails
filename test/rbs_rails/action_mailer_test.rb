require 'test_helper'

class ActionMailerTest < Minitest::Test
  def test_type_check
    clean_test_signatures

    setup!

    dir = app_dir
    sh!('steep', 'check', chdir: dir)
  end

  def test_user_mailer_rbs_snapshot
    clean_test_signatures

    setup!

    rbs_path = app_dir.join('sig/rbs_rails/app/mailers/user_mailer.rbs')
    expect_path = expectations_dir / 'user_mailer.rbs'
    # Code to re-generate the expectation files
    # expect_path.write rbs_path.read

    assert_equal expect_path.read, rbs_path.read
  end

  def app_dir
    Pathname(__dir__).join('../app')
  end

  def expectations_dir
    Pathname(__dir__).join('../expectations')
  end

  def setup!
    dir = app_dir

    Bundler.with_unbundled_env do
      sh!('bundle', 'install', chdir: dir)
      sh!('bin/rake', 'db:create', 'db:schema:load', chdir: dir)
      sh!('bin/rake', 'rbs_rails:all', '--trace', chdir: dir)
    end
  end
end
