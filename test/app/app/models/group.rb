class Group < ApplicationRecord
  has_many :users
  has_one :thumbnail, dependent: :destroy, required: false
  accepts_nested_attributes_for :users, :thumbnail
end
