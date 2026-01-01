class Order < ApplicationRecord
  self.primary_key = [:shop_id, :id]
  has_many :book
end
