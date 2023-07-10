# RBS Rails

RBS Rails is a RBS file generator for Ruby on Rails.
It generates for you:
- RBS signatures of all the methods defined by ActiveRecord for everyone of your models.
- RBS signatures of all the path/url helpers available in your application.

## Contents
* [Installation](#installation)
* [Configuration](#configuration)
* [Type checking a Rails app with RBS](#type-checking-a-rails-app-with-rbs)
  * [Step 0: Setup](#step-0-setup)
  * [Step 1: Using RBS Rails](#step-1-using-rbs-rails)
  * [Step 2: Custom signatures](#step-2-custom-signatures)
  * [Step 3: Type checking](#step-3-type-checking)
  * [Additional resources](#additional-resources)
* [Development](#development)
* [Contributing](#contributing)

## Installation

Add this line to your application's `Gemfile` and then execute `bundle install`:

```ruby
gem 'rbs_rails', require: false
```

Run the following command, which will generate `lib/tasks/rbs.rake`

    $ bin/rails generate rbs_rails:install

After the setup, the following three tasks are available:

* `bin/rails rbs_rails:generate_rbs_for_models`: Generate RBS files for your models, containing signatures for all the ActiveRecord-automatically-generated methods.
* `bin/rails rbs_rails:generate_rbs_for_path_helpers`: Generate an RBS file containing signatures for all the path/url helpers available in your application.
* `bin/rails rbs_rails:all`: Execute both above tasks.

## Configuration
You can specify the RBS Rails target path directly inside of the rake task.

```rb
require "rbs_rails/rake_task"

RbsRails::RakeTask.new do |task|
  task.signature_root_dir = 'my/own/custom/path'
end
```

## Type checking a Rails app with RBS
This section of the README will contain all the instruction to get you started for adding a type system to a Rails application.

### Step 0: Setup
The first step is setting up all the tools we are going to need.

First add the following gems to your `Gemfile`:
```ruby
  gem 'rbs', require: false
  gem 'rbs_rails', require: false
  gem 'steep', require: false
  gem 'typeprof', require: false # optional
```

Follow the [installation section](#installation) of this README to setup RBS Rails.

Then, configure `rbs collection` in order to load the RBS signatures for all your gem dependencies that don't ship directly with RBS files from the [rbs collection repository](https://github.com/ruby/gem_rbs_collection).

Run the following command to generate `rbs_collection.yaml`:

    $ bundle exec rbs collection init

Adjust the file configuration as you need and then load the actual RBS files from the repo with:

    $ bundle exec rbs collection install

It's recommended to remove the newly-generated folder from source control. You can do this by just adding its path to `.gitignore`.

Then, configure the actual type checker. Run:

    $ bundle exec steep init

which will create a `Steepfile`. Edit it with the following content:
```ruby
target :app do
  signature 'sig' # directory where we will store our signatures

  check 'app' # directory to type check
end
```
### Step 1: Using RBS Rails
Now that we have completed the setup, we can use RBS Rails to generate:
- an RBS file per model, containing signatures for the ActiveRecord-automatically-generated methods.
- an RBS file containing the signatures of the path/url helpers available in your application.

Run the following task to generate all the above-mentioned RBS files:

    $ bin/rails rbs_rails:all

Alternatively you can create RBS files only for the models or the path/url helpers with the other two tasks mentioned in the [installation section](#installation).

This task will created the folder `sig/rbs_rails` (or any custom folder you have specified in the [configuration](#configuration)) containing:
- `app/`, containing the RBS signatures of your models.
- `path_helpers.rbs`, containing an `Interface` that defines the signatures of your path/url helpers.

### Step 2: Custom signatures
Now that RBS Rails has done most of the work for us, it's time to write the signatures of all of our custom methods, which will be placed inside of a new folder called `sig/app`.

Theoretically, you should define a RBS signature for all the methods you have defined in each class/module inside of your main `app/` folder. This includes models, controllers, helpers, jobs, mailers and any other class/design-pattern that you are making use of.

NOTE that you should **never modify the RBS Rails generated RBS files**, as you will loose any modification the next time you run one of the three available rake tasks.

The structure of `sig/app` folder should directly reflect the one of your `app/` folder, and might look something like:

```
sig/
  app/
    models/ -> one RBS file per model, including signatures of the custom methods of the current model
    controllers/ -> one RBS file per controller, which should all include the `Interface` in `path_helpers.rbs`
    helpers/ -> one RBS file per helper
    jobs/ -> one RBS file per job
    mailers/ -> one RBS file per mailer
    ...
  rbs_rails/ -> rbs_rails generated signatures
```

Additionally, every class that inherits from a superclass should have an RBS file that match the actual hierarchy structure. For example, if you are defining signatures for your `ApplicationMailer`, which inherits from `ActionMailer::Base`, then you will have an RBS file that starts with:

```rb
class ApplicationMailer < ActionMailer::Base
```

In this case, the RBS definition of ActionMailer::Base is generated by `rbs collection`.

The same goes for modules. If you have a controller that inherits an helper, then the RBS for the controller should inherit that helper's RBS.

When defining your custom signatures, you can either write them one by one or you can leverage some tools to speed up your work. Those tools include:
- `rbs prototype`, a command that ships directly with RBS.
- `typeprof`, an [experimental type-level Ruby interpreter](https://github.com/ruby/typeprof).

Note that those tools will probably output many untyped signatures. It's your job to fix them as much as possible, but it's still better than writing all of them from scratch.

### Step 3: Type checking
Now that our work is finished, we can use `Steep` to type check our application!

You can run the following command in order to get an idea of how much typed your application is:

    $ bundle exec steep stats

In order to actually type check your app, run:

    $ bundle exec steep check

Note that it's very unlikely that you have written 100% correct signatures, so don't be discouraged if the type checker throws some errors.

### Additional resources
Here are a few other resources that will help you master your RBS skills:

- [RBS official repo](https://github.com/ruby/rbs/blob/master)
- [RBS exhaustive syntax reference](https://github.com/ruby/rbs/blob/master/docs/syntax.md)
- [Steep official repo](https://github.com/soutaro/steep/tree/master)
- [Typeprof official repo](https://github.com/ruby/typeprof)
- An incredible [introduction article](https://evilmartians.com/chronicles/climbing-steep-hills-or-adopting-ruby-types) on RBS by Evil Martians, written by Vladimir Dementyev (aka [Palkan](https://github.com/palkan))

## Development

After checking out the repo, run `bin/setup` to install dependencies.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/pocke/rbs_rails.
