require 'parser'
require 'prism'
require 'rbs'
require 'stringio'

require_relative "rbs_rails/version"
require_relative "rbs_rails/util"
require_relative 'rbs_rails/active_record'
require_relative 'rbs_rails/active_record/enum'
require_relative 'rbs_rails/path_helpers'
require_relative 'rbs_rails/dependency_builder'

module RbsRails
  class Error < StandardError; end

  # @rbs to: untyped
  def self.copy_signatures(to:) #: untyped
    from = Pathname(_ = __dir__) / '../assets/sig/'
    to = Pathname(to)
    FileUtils.cp_r(from, to)
  end
end
