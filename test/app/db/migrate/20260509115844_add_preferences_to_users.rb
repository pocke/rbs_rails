class AddPreferencesToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :preferences, :text
  end
end
