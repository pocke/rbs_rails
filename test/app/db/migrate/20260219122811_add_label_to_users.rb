class AddLabelToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :label, :integer, null: false
  end
end
