class User < ApplicationRecord
  scope :all_kind_args, -> (type, m = 1, n = 1, *rest, x, k: 1,**untyped, &blk)  { all }
  scope :no_arg, -> ()  { all }

  has_and_belongs_to_many :blogs
  has_secure_password

  serialize :phone_numbers, Array
  serialize :contact_info, Hash
  serialize :family_tree, JSON

  has_one_attached :avatar

  enum :status, [:temporary, :accepted], default: :temporary
end
