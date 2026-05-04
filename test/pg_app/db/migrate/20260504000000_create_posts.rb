class CreatePosts < ActiveRecord::Migration[7.2]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.string :tags, array: true
      t.integer :scores, array: true, null: false, default: []

      t.timestamps null: false
    end
  end
end
