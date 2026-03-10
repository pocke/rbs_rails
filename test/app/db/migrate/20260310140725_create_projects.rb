# frozen_string_literal: true

class CreateProjects < ActiveRecord::Migration[7.2]
  def change
    create_table :projects, id: :string do |t|
      t.string :name
      t.timestamps
    end
  end
end
