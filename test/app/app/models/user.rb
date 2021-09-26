class User < ApplicationRecord
  scope :all_kind_args, -> (type, m = 1, n = 1, *rest, x, k: 1,**untyped, &blk)  { all }
  scope :no_arg, -> ()  { all }

  has_and_belongs_to_many :blogs
  has_secure_password

  enum status: {
    temporary: 1,
    accepted: 2,
  }
end
