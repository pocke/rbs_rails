ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
# Disable Bootsnap due to https://github.com/pocke/rbs_rails/pull/198#issuecomment-931215730
# require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
