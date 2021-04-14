class User < ApplicationRecord
  scope :all_kind_args, -> (a, m = 1, n = 1, *rest, x, k: 1, **kwrest, &blk)  { all }
  scope :no_arg, -> ()  { all }

  has_and_belongs_to_many :blogs
end
