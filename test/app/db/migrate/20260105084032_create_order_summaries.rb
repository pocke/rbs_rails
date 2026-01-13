class CreateOrderSummaries < ActiveRecord::Migration[7.2]
  def change
    create_table :order_summaries, primary_key: [:shop_id, :price]  do |t|
      t.datetime :summary_on, null: false
      t.integer :shop_id, null: false
      t.integer :price, null: false

      t.timestamps
    end
  end
end
