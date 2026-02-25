class User < ApplicationRecord
  alias_attribute :alias_name, :name
  alias_attribute :alias_role, :role

  scope :all_kind_args, -> (type, m = 1, n = 1, *rest, x, k: 1,**untyped, &blk)  { all }
  scope :no_arg, -> ()  { all }
  scope :popular, PopularQuery

  belongs_to :group
  has_and_belongs_to_many :blogs
  has_secure_password

  serialize :phone_numbers, type: Array
  serialize :contact_info, type: Hash
  serialize :family_tree, coder: JSON

  has_one_attached :avatar

  enum :status, [:temporary, :accepted], default: :temporary
  enum :alias_role, [:member, :manager], default: :member
  enum :label, [:gold, :silver], default: :gold, scopes: false, instance_methods: false
end
