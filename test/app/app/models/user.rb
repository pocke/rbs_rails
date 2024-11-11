class User < ApplicationRecord
  scope :all_kind_args, -> (type, m = 1, n = 1, *rest, x, k: 1,**untyped, &blk)  { all }
  scope :no_arg, -> ()  { all }

  has_and_belongs_to_many :blogs
  has_secure_password

  has_one_attached :avatar

  enum status: {
    temporary: 1,
    accepted: 2,
  }, _default: :temporary

  enum timezone: {
    'America/Los_Angeles': 'America/Los_Angeles',
    'America/Denver': 'America/Denver',
    'America/Chicago': 'America/Chicago',
    'America/New_York': 'America/New_York'
  }
end
