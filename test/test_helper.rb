require 'minitest'
require 'minitest/autorun'

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
