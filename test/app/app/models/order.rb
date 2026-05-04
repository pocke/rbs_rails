class Order < ApplicationRecord
  self.primary_key = [:shop_id, :id]
  has_many :book

  attribute :tax_rate, :float, default: 0.1
  attribute :gift_message, :string
end
