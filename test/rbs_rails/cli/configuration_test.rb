require 'test_helper'
require 'active_record'
require 'rbs_rails/cli'
require_relative "../../app/config/application"

class ConfigurationTest < Minitest::Test
  class User < ActiveRecord::Base
  end

  class Blog < ActiveRecord::Base
  end

  def setup
    RbsRails::CLI::Configuration.instance.send(:initialize)
  end

  def teardown
    RbsRails::CLI::Configuration.instance.send(:initialize)
  end

  def test_singleton_behavior
    config1 = RbsRails::CLI::Configuration.instance
    config2 = RbsRails::CLI::Configuration.instance

    assert_same config1, config2
  end

  def test_default_signature_root_dir
    config = RbsRails::CLI::Configuration.instance
    expected = Rails.root.join("sig/rbs_rails")

    assert_equal expected, config.signature_root_dir
  end

  def test_signature_root_dir_with_string
    path = "path/to/sig"

    RbsRails.configure do |config|
      config.signature_root_dir = path
    end

    config = RbsRails::CLI::Configuration.instance
    assert_equal Pathname.new(path), config.signature_root_dir
  end

  def test_signature_root_dir_with_pathname
    path = Pathname.new("path/to/sig")

    RbsRails.configure do |config|
      config.signature_root_dir = path
    end

    config = RbsRails::CLI::Configuration.instance
    assert_equal path, config.signature_root_dir
  end

  def test_default_ignored_model
    config = RbsRails::CLI::Configuration.instance

    refute config.ignored_model?(User)
  end

  def test_ignored_model_with_user_defined_block
    RbsRails.configure do |config|
      config.ignore_model_if do |klass|
        klass.name == "ConfigurationTest::User"
      end
    end

    config = RbsRails::CLI::Configuration.instance

    assert config.ignored_model?(User)
    refute config.ignored_model?(Blog)
  end
end
