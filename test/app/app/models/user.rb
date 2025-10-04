class User < ApplicationRecord
  alias_attribute :alias_name, :name
  scope :all_kind_args, -> (type, m = 1, n = 1, *rest, x, k: 1,**untyped, &blk)  { all }
  scope :no_arg, -> ()  { all }

  belongs_to :group
  has_and_belongs_to_many :blogs
  has_secure_password

  serialize :phone_numbers, type: Array
  serialize :contact_info, type: Hash
  serialize :family_tree, coder: JSON

  has_one_attached :avatar

  enum :status, [:temporary, :accepted], default: :temporary
end
