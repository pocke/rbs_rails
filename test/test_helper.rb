require 'minitest'
require 'minitest/autorun'
require 'minitest/hooks'

require 'pathname'
require 'bundler'
require 'rbs_rails'

TEST_SIG_DIR = Pathname(File.expand_path('./app/sig/rbs_rails', __dir__))

def clean_test_signatures
  return unless TEST_SIG_DIR.exist?
  File.delete(*TEST_SIG_DIR.glob('**/*.rbs'))
end

def sh!(*commands, **kw)
  puts '$ ' + commands.join(' ')
  system(*commands, exception: true, **kw)
end

def app_dir
  Pathname(__dir__).join('app')
end

def expectations_dir
  Pathname(__dir__).join('expectations')
end

def setup!(rbs_rails: true)
  dir = app_dir

  Bundler.with_unbundled_env do
    sh!('bundle', 'install', chdir: dir)
    sh!('bin/rake', 'db:create', 'db:schema:load', chdir: dir)
    sh!('bin/rake', 'rbs_rails:all', '--trace', chdir: dir) if rbs_rails
  end
end

# Constant stubbing capabilities for tests
module ConstStubbable
  def stub_const(const_name, new_value)
    @stub_const ||= {}

    const_name = const_name.to_sym
    if Object.const_defined?(const_name, false)
      @stub_const[const_name] = Object.const_get(const_name)
      Object.send(:remove_const, const_name)
    else
      @stub_const[const_name] = nil
    end

    Object.const_set(const_name, new_value)
  end

  def clean_const_stubs
    return unless @stub_const

    @stub_const.each do |const_name, original|
      Object.send(:remove_const, const_name) if Object.const_defined?(const_name, false)
      Object.const_set(const_name, original) if original
    end

    @stub_const.clear
  end
end
