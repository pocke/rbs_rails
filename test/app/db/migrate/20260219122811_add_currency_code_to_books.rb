class AddCurrencyCodeToBooks < ActiveRecord::Migration[7.2]
  def change
    add_column :books, :currency_code, :string, null: false
  end
end
