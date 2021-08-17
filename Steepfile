target :lib do
  signature "sig"
  signature 'assets/sig'

  check "lib"                       # Directory name
  repo_path ENV['RBS_REPO_DIR'] if ENV['RBS_REPO_DIR']

  # rbs collection
  # TODO: Move the implementation to Steep
  lock = RBS::Collection::Config.lockfile_of(Pathname('./rbs_collection.yaml'))
  repo_path lock.repo_path

  lock.gems.each do |gem|
    library "#{gem['name']}:#{gem['version']}"
  end
end
