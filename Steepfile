target :lib do
  signature "sig"
  signature 'assets/sig'

  check "lib"                       # Directory name
  repo_path ENV['RBS_REPO_DIR'] || './gem_rbs'

  library "pathname"
  library "logger"
  library "mutex_m"
  library "date"

  library 'activesupport'
  library 'actionpack'
  library 'activejob'
  library 'activemodel'
  library 'actionview'
  library 'activerecord'
  library 'railties'
end
