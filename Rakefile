require "bundler/gem_tasks"
task :default => [:rbs_validate, :steep]

desc 'run Steep'
task :steep do
  sh 'steep', 'check'
end

task :rbs_validate do
  sh 'bin/rbs validate'
end
