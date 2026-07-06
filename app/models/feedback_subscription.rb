class FeedbackSubscription < ApplicationRecord
  belongs_to :feedback_submission
  belongs_to :user

  validates :user_id, uniqueness: { scope: :feedback_submission_id }

  scope :subscribed, -> { where(subscribed: true) }
  scope :unsubscribed, -> { where(subscribed: false) }
end
