class CreateStatusChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :status_changes do |t|
      t.references :feedback_submission, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :from_status, null: false
      t.string :to_status, null: false
      t.text :note
      t.timestamps
    end
  end
end
