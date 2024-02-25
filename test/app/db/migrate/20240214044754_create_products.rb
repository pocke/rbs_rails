class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products, primary_key: [:store_id, :sku] do |t|
      t.integer :store_id, null: false
      t.string :sku, null: false
      t.text :description

      t.timestamps
    end
  end
end
