require 'test_helper'

class ActiveRecordTest < Minitest::Test
  def test_type_check
    clean_test_signatures

    signature_path = Pathname(File.expand_path('../sig', __dir__))
    RbsRails.copy_signatures(to: signature_path)

    dir = File.expand_path('../app', __dir__)

    Bundler.with_unbundled_env do
      sh!('bundle', 'install', chdir: dir)
      sh!('bin/rake', 'db:create', 'db:schema:load', chdir: dir)
      sh!('bin/rake', 'generate_rbs_for_model', chdir: dir)
    end
    sh!('steep', 'check', chdir: dir)
  end
end
