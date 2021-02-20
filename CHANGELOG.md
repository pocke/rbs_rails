# Change log

## master (unreleased)

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
