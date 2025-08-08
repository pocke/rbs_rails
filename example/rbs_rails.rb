# Example configuration file for rbs_rails
#
# Place this file in the root of your Rails project or in config/rbs_rails.rb

RbsRails.configure do |config|
  # Specify the directory where RBS signatures will be generated
  # Default: Rails.root.join("sig/rbs_rails")
  config.signature_root_dir = "sig/rbs_rails"

  # Define a proc to determine which models should be ignored during generation
  # The proc receives a model class and should return true if the model should be ignored
  config.ignore_model_if do |klass|
    # Example: Ignore test models
    klass.name.start_with?("Test") ||
    # Example: Ignore models in the Admin namespace
    klass.name.start_with?("Admin::") ||
    # Example: Ignore models that are not backed by a database table
    !klass.table_exists? ||
    # Example: Ignore anonymous classes
    klass.name.blank?
  end
end
