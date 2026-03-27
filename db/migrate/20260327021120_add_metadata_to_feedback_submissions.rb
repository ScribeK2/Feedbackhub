class AddMetadataToFeedbackSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :feedback_submissions, :priority, :string
    add_column :feedback_submissions, :feedback_type, :string
    add_column :feedback_submissions, :ticket_number, :string
    add_index :feedback_submissions, :priority
    add_index :feedback_submissions, :feedback_type
    add_index :feedback_submissions, :ticket_number
  end
end
