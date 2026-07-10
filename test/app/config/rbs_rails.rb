RbsRails.configure do |config|
  config.ignore_model_if do |klass|
    # klass.name == "User"
    klass.name == "Article"
  end
end
