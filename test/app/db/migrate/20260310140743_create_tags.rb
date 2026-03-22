# frozen_string_literal: true

class CreateTags < ActiveRecord::Migration[7.2]
  def change
    create_table :tags, id: :string do |t|
      t.references :project, null: false, foreign_key: true, type: :string
      t.string :name
      t.timestamps
    end
  end
end
