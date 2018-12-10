class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks do |t|
      t.boolean :status
      t.references :product, foreign_key: true
      t.integer :tasks, :tasks_count, :integer, default: 0
      t.timestamps
    end
  end
end