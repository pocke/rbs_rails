class DeliveryAddress < ApplicationRecord
  belongs_to :user

  composed_of :address,
    class_name: "Address",
    mapping: [
      %w[postal_code    postal_code],
      %w[prefecture     prefecture],
      %w[city           city],
      %w[street_address street_address],
      %w[building_name  building_name]
    ]
end
