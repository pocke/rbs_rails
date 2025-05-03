require "bundler/gem_tasks"
require 'rake/testtask'

task :default => [:rbs_update, :rbs_validate, :steep, :test]

desc 'run Steep'
task :steep do
  sh 'steep', 'check'
end

task :rbs_update do
  rm_rf('sig/rbs_rails')
  sh 'rbs-inline', '--opt-out', '--output=sig/', 'lib'
end

task :rbs_validate do
  repo = ENV['RBS_REPO_DIR']&.then do |env|
    "--repo=#{env}"
  end
  sh "rbs #{repo} validate"
end

Rake::TestTask.new do |test|
  test.libs << 'test'
  test.test_files = Dir['test/**/*_test.rb']
  test.verbose = true
end
