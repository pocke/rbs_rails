class Book < ApplicationRecord
  belongs_to :order

  enum :currency_code, jpy: 'JPY', usd: 'USD', eur: 'EUR'

  composed_of :money, class_name: '::Book::Money', mapping: { price: :price, currency_code: :currency_code }
end
