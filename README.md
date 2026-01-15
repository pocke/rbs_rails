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

Run the following command. It generates `lib/tasks/rbs.rake`.

```console
$ bin/rails g rbs_rails:install
```

Then, the following three tasks are available.

* `rbs_rails:generate_rbs_for_mailers`: Generate RBS files for Action Mailer classes
* `rbs_rails:generate_rbs_for_models`: Generate RBS files for Active Record models
* `rbs_rails:generate_rbs_for_path_helpers`: Generate RBS files for path helpers
* `rbs_rails:all`: Execute all tasks of RBS Rails

You can also run rbs_rails from command line:

```console
# Generate all RBS files
$ bundle exec rbs_rails all

# Generate RBS files for mailers
$ bundle exec rbs_rails mailers

# Generate RBS files for models
$ bundle exec rbs_rails models

# Generate RBS files for path helpers
$ bundle exec rbs_rails path_helpers
```

### Install RBS for `rails` gem

You need to install `rails` gem's RBS files. I highly recommend using `rbs collection`.

1. Add `gem 'rails'` to your `Gemfile`.
1. Then execute the following commands
   ```console
   $ bundle install
   $ bundle exec rbs collection init
   $ bundle exec rbs collection install
   ```

### Configuration

You can customize the behavior of rbs_rails via configuration file. Place one of the following files in your project:

* `.rbs_rails.rb` (in the project root)
* `config/rbs_rails.rb`

```ruby
RbsRails.configure do |config|
  # Specify the directory where RBS signatures will be generated
  # Default: Rails.root.join("sig/rbs_rails")
  config.signature_root_dir = "sig/rbs_rails"

  # Enable or disable checking for database migrations.
  # If enabled, rbs_rails stops to generate RBS files if database is not migrated to the latest version.
  # Default: enabled
  check_db_migrations = true

  # Define which models should be ignored during generation
  config.ignore_model_if do |klass|
    # Example: Ignore test models
    klass.name.start_with?("Test") ||
    # Example: Ignore models in specific namespaces
    klass.name.start_with?("Admin::") ||
    # Example: Ignore models without database tables
    !klass.table_exists?
  end
end
```

### Steep integration

Put the following code as `Steepfile`.

```ruby
target :app do
  signature 'sig'

  check 'app'
end
```

That's all! Now you can check your Rails app statically with `steep check` command.

## Development

After checking out the repo, run `bin/setup` to install dependencies.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

This gem uses [RBS::Inline](https://github.com/soutaro/rbs-inline) to generate RBS files.  Please mark up your code with RBS comments.
And then, run `bundle exec rake rbs_update` to reflect the type definitions to the RBS files.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and push it to the GitHub (via Pull Request).  Then, GitHub Actions will automatically create a release tag and publish the gem to rubygems.org.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pocke/rbs_rails.

