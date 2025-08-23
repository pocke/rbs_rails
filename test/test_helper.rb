require 'minitest'
require 'minitest/autorun'
require 'minitest/hooks'

require 'pathname'
require 'rbs_rails'

TEST_SIG_DIR = Pathname(File.expand_path('./app/sig/rbs_rails', __dir__))

def clean_test_signatures
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

def setup!
  dir = app_dir

  Bundler.with_unbundled_env do
    sh!('bundle', 'install', chdir: dir)
    sh!('bin/rake', 'db:create', 'db:schema:load', chdir: dir)
    sh!('bin/rake', 'rbs_rails:all', '--trace', chdir: dir)
  end
end
