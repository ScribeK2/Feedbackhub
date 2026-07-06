class AddSubmitterToFeedbackSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_reference :feedback_submissions, :submitter, foreign_key: { to_table: :users }
  end
end
