class CreateUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :updates do |t|
      t.boolean :pinned, null: false, default: false
      t.date :date, null: false
      t.references :author, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
