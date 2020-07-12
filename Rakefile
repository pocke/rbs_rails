require "bundler/gem_tasks"
task :default => [:rbs_validate, :steep]

desc 'run Steep'
task :steep do
  sh 'steep', 'check'
end

task :rbs_validate do
  sh 'rbs', '-rlogger', '-rpathname', '-rmutex_m', '-Isig', '-Iassets/sig', 'validate'
end
