# RBS Rails

RBS files generator for Ruby on Rails.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rbs_rails', require: false
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rbs_rails

## Usage

Put the following code to `lib/tasks/rbs.rake`.

```ruby
require 'rbs_rails/rake_task'

RbsRails::RakeTask.new
```

Then, the following four tasks are available.

* `rbs_rails:copy_signature_files`: Copy RBS files for rbs_rails
* `rbs_rails:generate_rbs_for_models`: Generate RBS files for Active Record models
* `rbs_rails:generate_rbs_for_path_helpers`: Generate RBS files for path helpers
* `rbs_rails:all`: Execute all tasks of RBS Rails




### Steep integration

You need to specify the following libraries by `Steepfile`.

```ruby
# Steepfile

target :app do
  signature 'sig'

  check 'app'

  repo_path "path/to/rbs_repo"

  library 'pathname'
  library 'logger'
  library 'mutex_m'
  library 'date'

  library 'activesupport'
  library 'actionpack'
  library 'activejob'
  library 'activemodel'
  library 'actionview'
  library 'activerecord'
  library 'railties'
end
```

You need to put RBS repo to `path/to/rbs_repo`. See https://github.com/ruby/gem_rbs

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pocke/rbs_rails.

