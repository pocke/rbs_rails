class Address
  attr_reader :postal_code, :prefecture, :city, :street_address, :building_name

  def initialize(postal_code, prefecture, city, street_address, building_name)
    @postal_code    = postal_code
    @prefecture     = prefecture
    @city           = city
    @street_address = street_address
    @building_name  = building_name
  end

  def to_s
    "〒#{postal_code} #{prefecture}#{city}#{street_address}#{building_name}"
  end

  def ==(other)
    postal_code    == other.postal_code &&
    prefecture     == other.prefecture &&
    city           == other.city &&
    street_address == other.street_address &&
    building_name  == other.building_name
  end
end
