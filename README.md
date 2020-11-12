# RBS Rails

RBS files generator for Ruby on Rails.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rbs_rails'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rbs_rails

## Usage

### For Active Record models

It has two tasks.

* `copy_signature_files`: Copy type definition files for Rails from rbs_rails.
* `generate_rbs_for_model`: Generate RBS files from model classes.

```ruby
# Rakefile

task copy_signature_files: :environment do
  require 'rbs_rails'

  to = Rails.root.join('sig/rbs_rails/')
  to.mkpath unless to.exist?
  RbsRails.copy_signatures(to: to)
end

task generate_rbs_for_model: :environment do
  require 'rbs_rails'

  out_dir = Rails.root / 'sig'
  out_dir.mkdir unless out_dir.exist?

  Rails.application.eager_load!

  ActiveRecord::Base.descendants.each do |klass|
    next if klass.abstract_class?

    path = out_dir / "app/models/#{klass.name.underscore}.rbs"
    FileUtils.mkdir_p(path.dirname)

    sig = RbsRails::ActiveRecord.class_to_rbs(klass)
    path.write sig
  end
end
```

### For path helpers

```ruby
# Rakefile

task generate_rbs_for_path_helpers: :environment do
  require 'rbs_rails'
  out_path = Rails.root.join 'sig/path_helpers.rbs'
  rbs = RbsRails::PathHelpers.generate
  out_path.write rbs
end
```

### Steep integration

You need to specify the following libraries by `Steepfile`.

```ruby
# Steepfile

target :app do
  signature 'sig'

  check 'app'

  library 'pathname'
  library 'logger'
  library 'mutex_m'
  library 'date'
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pocke/rbs_rails.

