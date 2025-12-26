class Init < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.references :group, null: false, foreign_key: true, index: true
      t.integer :age, null: false
      t.integer :status, null: false
      t.string :phone_numbers
      t.string :contact_info
      t.string :family_tree

      t.timestamps null: false
    end
  end
end
