class OrderSummary < ApplicationRecord
  self.primary_key = [:shop_id, :summary_on]

  validates :summary_on, presence: true
  validates :shop_id, presence: true
  validates :price, presence: true
end
