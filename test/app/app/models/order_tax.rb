# frozen_string_literal: true

class OrderTax < ApplicationRecord
  belongs_to :order
end
