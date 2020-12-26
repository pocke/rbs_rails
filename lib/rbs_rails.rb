require 'parser/current'
require 'rbs'
require 'stringio'

require_relative "rbs_rails/version"
require_relative 'rbs_rails/active_record'
require_relative 'rbs_rails/path_helpers'

module RbsRails
  class Error < StandardError; end

  def self.copy_signatures(to:)
    from = Pathname(_ = __dir__) / '../assets/sig/'
    to = Pathname(to)
    FileUtils.cp_r(from, to)
  end
end
