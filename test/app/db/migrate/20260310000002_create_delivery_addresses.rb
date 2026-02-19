class CreateDeliveryAddresses < ActiveRecord::Migration[7.2]
  def change
    create_table :delivery_addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :postal_code, null: false
      t.string :prefecture, null: false
      t.string :city, null: false
      t.string :street_address, null: false
      t.string :building_name

      t.timestamps
    end
  end
end
