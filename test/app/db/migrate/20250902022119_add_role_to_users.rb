class AddRoleToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :role, :integer, null: false, default: 0 # member
    change_column_default :users, :role, from: 0, to: nil
  end
end
