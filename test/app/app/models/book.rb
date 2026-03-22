class Book < ApplicationRecord
  belongs_to :order

  enum :currency_code, jpy: 'JPY', usd: 'USD', eur: 'EUR', allow_nil: true

  composed_of :money, class_name: 'Money', mapping: { price: :price, currency_code: :currency_code }, allow_nil: true
end
