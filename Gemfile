source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in rbs_rails.gemspec
gemspec

gem "rake", "~> 13.0"
gem 'rails', '>= 7.0'
gem 'rbs', '>= 3'
gem 'rbs-inline', require: false
gem 'steep', '>= 1.4', require: false
gem 'minitest'
gem 'minitest-hooks'

# Temporary workaround for Ruby 4.1+ where tsort is no longer bundled.
# Can be removed once rbs adds tsort as a runtime dependency.
gem 'tsort'
