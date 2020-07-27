require 'test_helper'

class ActiveRecordTest < Minitest::Test
  def test_type_check
    clean_test_signatures

    signature_path = Pathname(File.expand_path('../sig', __dir__))
    RbsRails.copy_signatures(to: signature_path)

    Bundler.with_unbundled_env do
      sh!('bin/rake', 'generate_rbs_for_model', chdir: File.expand_path('../app', __dir__))
    end
    sh!('steep', 'check', chdir: File.expand_path('../app', __dir__))
  end
end
