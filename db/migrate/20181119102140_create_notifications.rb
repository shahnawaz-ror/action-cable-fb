# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :notifications do |t|
      t.string :title
      t.text :description
      t.boolean :status, default: false

      t.timestamps
    end
  end
end
