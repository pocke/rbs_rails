class AddStatusToUsers < ActiveRecord::Migration[7.1]
  def change
    change_column :users, :status, :integer, default: 1, null: false
  end
end
