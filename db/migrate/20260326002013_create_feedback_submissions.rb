class CreateFeedbackSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :feedback_submissions do |t|
      t.references :feedback_template, null: false, foreign_key: true
      t.json :data, null: false, default: {}
      t.string :csr_name
      t.string :submitted_by

      t.timestamps
    end

    add_index :feedback_submissions, :csr_name
    add_index :feedback_submissions, :submitted_by
  end
end
