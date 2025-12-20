class Group < ApplicationRecord
  has_many :users
  has_one :thumbnail, dependent: :destroy, required: false
end
