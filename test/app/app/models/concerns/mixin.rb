module Mixin
  extend ActiveSupport::Concern
  included do
    scope :mixin, -> () {}
  end
end
