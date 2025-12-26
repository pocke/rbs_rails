class CreateBooks < ActiveRecord::Migration[6.1]
  def change
    create_table :books do |t|
      t.integer :order_id
      t.integer :price

      t.timestamps
    end
  end
end
