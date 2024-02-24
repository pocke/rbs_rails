class Product < ApplicationRecord
  self.primary_key = [:store_id, :sku]
end
