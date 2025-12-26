class CreateOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :orders, primary_key: [:shop_id, :id] do |t|
      t.integer :id
      t.integer :shop_id
      t.integer :price

      t.timestamps
    end
  end
end
