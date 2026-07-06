class CreateFeedbackSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :feedback_subscriptions do |t|
      t.references :feedback_submission, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :subscribed, null: false, default: true
      t.timestamps
    end
    add_index :feedback_subscriptions, [ :feedback_submission_id, :user_id ], unique: true
  end
end
