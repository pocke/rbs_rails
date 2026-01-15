# Change log

## master (unreleased)

## 0.13

### New features

* Enable type generation for models with composite primary keys [#358](https://github.com/pocke/rbs_rails/pull/358)
* Add optional arguments for column_changed? and column_previously_changed? [#357](https://github.com/pocke/rbs_rails/pull/357)
* Check database migrations before generating types for models [#342](https://github.com/pocke/rbs_rails/pull/342)
* Integrate model_dependencies.rbs to each model signatures [#345](https://github.com/pocke/rbs_rails/pull/345)
* Do not update RBS file if the signature nothing changed [#346](https://github.com/pocke/rbs_rails/pull/346)
* support alias attribute in enum definitions [#325](https://github.com/pocke/rbs_rails/pull/325)
* active_record: Support #id_value alias for #id column [#350](https://github.com/pocke/rbs_rails/pull/350)
* Allow overrides methods in subclasses [#317](https://github.com/pocke/rbs_rails/pull/317)
* feat: Add command line interface for rbs_rails [#335](https://github.com/pocke/rbs_rails/pull/335)
* feat: Display class name when RBS generation fails [#334](https://github.com/pocke/rbs_rails/pull/334)
* Support no-arguments in create_** method for has_one associations [#333](https://github.com/pocke/rbs_rails/pull/333)
* Add #{attribute}_before_type_cast and #{attribute}_for_database methods for attributes [#322](https://github.com/pocke/rbs_rails/pull/322)
* Support has_and_belongs_to_many [#272](https://github.com/pocke/rbs_rails/pull/272)
* Support special directory structures, such as when using packs-rails [#323](https://github.com/pocke/rbs_rails/pull/323)
* enum: Support Rails 7 style enum definitions [#311](https://github.com/pocke/rbs_rails/pull/311)
* add generate columns aliased by alias_attibute [#318](https://github.com/pocke/rbs_rails/pull/318)
* Add additional enum methods [#312](https://github.com/pocke/rbs_rails/pull/312)
* enum: Support array-style enum declarations [#310](https://github.com/pocke/rbs_rails/pull/310)
* Support resolve-type-names header [#304](https://github.com/pocke/rbs_rails/pull/304)
* Install _RbsRailsPathHelpers to ActionController::Base by default [#279](https://github.com/pocke/rbs_rails/pull/279)
* Override types of CollectionProxy [#289](https://github.com/pocke/rbs_rails/pull/289)
* path_helpers: Support Rails 8.0 [#283](https://github.com/pocke/rbs_rails/pull/283)
* Reimplement enum inspector via spy  [#296](https://github.com/pocke/rbs_rails/pull/296)
* generated rbs for activerecord models respects serialize (common cases) [#293](https://github.com/pocke/rbs_rails/pull/293)

### Bug fixes

* Avoid reusing the same object when generating attribute aliases [#361](https://github.com/pocke/rbs_rails/pull/361)
* Use Prism instead of parser/current to suppress warnings [#362](https://github.com/pocke/rbs_rails/pull/362)
* Fix: Ruby::UnresolvedOverloading error when calling ::ActiveRecord::Relation#select [#353](https://github.com/pocke/rbs_rails/pull/353)
* CI: Fix broken testcases [#336](https://github.com/pocke/rbs_rails/pull/336)
* fix: external library models not saved to correct path structure [#324](https://github.com/pocke/rbs_rails/pull/324)
* Fix [#{](https://github.com/pocke/rbs_rails/pull/{)attribute}_before_type_cast and {#attribute}_for_database methods test #330
* test: Adjust expectations for Blog model [#327](https://github.com/pocke/rbs_rails/pull/327)
* Fix [#233](https://github.com/pocke/rbs_rails/pull/233): Support enum name including unexpected characters #285
* test: Update db/schema.rb on test app [#307](https://github.com/pocke/rbs_rails/pull/307)
* Fix [#277](https://github.com/pocke/rbs_rails/pull/277): CollectionProxy should include Enumerable explicitly #278

### misc

* CI: Hello Ruby 4.0! [#359](https://github.com/pocke/rbs_rails/pull/359)
* deps: Drop Rails 6 support [#355](https://github.com/pocke/rbs_rails/pull/355)
* test: Share build results across tests to reduce build times [#337](https://github.com/pocke/rbs_rails/pull/337)
* CI: Add GitHub Actions workflow for releasing gem [#309](https://github.com/pocke/rbs_rails/pull/309)
* test: Upgrade testing Rails app to 7.2  [#321](https://github.com/pocke/rbs_rails/pull/321)
* Manage types of this gem using RBS::Inline [#300](https://github.com/pocke/rbs_rails/pull/300)
* rake: Remove deprecated --silent option from rbs validate [#306](https://github.com/pocke/rbs_rails/pull/306)
* CI: Test with ruby 3.4 💎 [#301](https://github.com/pocke/rbs_rails/pull/301)
* sig: Remove sig/rake.rbs  [#295](https://github.com/pocke/rbs_rails/pull/295)
* Add path helper method tests [#292](https://github.com/pocke/rbs_rails/pull/292)
* deps: Add benchmark gem to test/app/Gemfile [#294](https://github.com/pocke/rbs_rails/pull/294)

## 0.12.1

* Drop support for old Rubies. [#284](https://github.com/pocke/rbs_rails/pull/284)
* Make type names absolute to avoid referring to incorrect class. [#265](https://github.com/pocke/rbs_rails/pull/265)
* Avoid to create directory on initialization. [#261](https://github.com/pocke/rbs_rails/pull/261)
* Make `build_*` methods parameters optional. [#258](https://github.com/pocke/rbs_rails/pull/258)
* Skip to define rake tasks when rbs_rails is not able to load. [#251](https://github.com/pocke/rbs_rails/pull/251)

## 0.12.0

* Support RBS v3. [#246](https://github.com/pocke/rbs_rails/pull/246)
* Ignore `_scope` as enum field name. [#249](https://github.com/pocke/rbs_rails/pull/249)

## 0.11.0 (2022-03-24)

### New Features

* Add rails generator to generate rbs.rake. [#217](https://github.com/pocke/rbs_rails/pull/217)

### Bug Fixes

* Do not expose polyfil RBSs. [#218](https://github.com/pocke/rbs_rails/pull/218)

## 0.10.1 (2022-03-23)

### Bug Fixes

* Generate dependency types of relations. [#216](https://github.com/pocke/rbs_rails/pull/216)

## 0.10.0 (2022-03-18)

### New Features

* Support `has_secure_password`. [#193](https://github.com/pocke/rbs_rails/pull/193)
* Support Active Storage. [#195](https://github.com/pocke/rbs_rails/pull/195)

### Bug Fixes

* Use absolute path for class names to avoid using incorrect class. [#201](https://github.com/pocke/rbs_rails/pull/201)
* Fix NoMethodError on enum with `_default` option. [#208](https://github.com/pocke/rbs_rails/pull/208)

## 0.9.0 (2021-09-18)

### New Features

* Support delegated_type association. [#181](https://github.com/pocke/rbs_rails/pull/181)

### Bug Fixes

* Fix error on a table that doesn't have the PK. [#121](https://github.com/pocke/rbs_rails/pull/121)
* Quote variable names to avoid syntax errors. [#178](https://github.com/pocke/rbs_rails/pull/178)
* Add scope methods to `ActiveRecord_Associations_CollectionProxy`. [#182](https://github.com/pocke/rbs_rails/pull/182)
* Make `has_one` association optional. [#180](https://github.com/pocke/rbs_rails/pull/180)
* Omit some methods for polymorphic associations. [#184](https://github.com/pocke/rbs_rails/pull/184)
* Include enum methods to GeneratedRelationMethods. [#183](https://github.com/pocke/rbs_rails/pull/183)
* Include `_ActiveRecord_Relation` to `CollectionProxy`. [#189](https://github.com/pocke/rbs_rails/pull/189)

## 0.8.2 (2021-02-20)

*  Add ActiveRecord::AttributeMethods::Dirty methods [#104](https://github.com/pocke/rbs_rails/pull/104)
*  Define find method based on primary key [#105](https://github.com/pocke/rbs_rails/pull/105)

## 0.8.1 (2021-01-09)

* Skip generation RBS fro class that doesn't have table in DB. [#95](https://github.com/pocke/rbs_rails/pull/95)

## 0.8.0 (2020-12-31)

* **[BREAKING]** Move RBS files that are copied by `rbs_rails:copy_signature_files` task to [ruby/gem_rbs](https://github.com/ruby/gem_rbs) repository [#90](https://github.com/pocke/rbs_rails/pull/90)
* Allow all kinds of argument for scope [#89](https://github.com/pocke/rbs_rails/pull/89)

## 0.7.0 (2020-12-28)

* **[BREAKING]** Re-structure signature directory. [#86](https://github.com/pocke/rbs_rails/pull/86)
* Generate ActiveRecord models with namespaces and superclasses. [#87](https://github.com/pocke/rbs_rails/pull/87)
