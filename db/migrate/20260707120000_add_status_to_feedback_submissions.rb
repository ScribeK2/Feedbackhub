class AddStatusToFeedbackSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :feedback_submissions, :status, :string, null: false, default: "open"
    add_index :feedback_submissions, :status
  end
end
