class CreateCsrs < ActiveRecord::Migration[8.1]
  def change
    create_table :csrs do |t|
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.references :user, foreign_key: true
      t.timestamps
    end
    add_index :csrs, :name, unique: true
  end
end
