class Comment < ApplicationRecord
  belongs_to :feedback_submission
  belongs_to :author, class_name: "User"

  has_many :notifications, as: :event, dependent: :destroy

  validates :body, presence: true

  scope :chronological, -> { order(created_at: :asc) }

  after_create_commit :subscribe_author
  after_create_commit :notify_recipients
  after_create_commit :broadcast_comment

  def notification_headline
    "#{author.name} commented on feedback for #{feedback_submission.csr_label}"
  end

  def notification_body
    body
  end

  private

  # An explicit opt-out (subscribed: false) is sticky; commenting only creates
  # a subscription when the author has no row yet.
  def subscribe_author
    feedback_submission.feedback_subscriptions.find_or_create_by!(user: author)
  end

  def notify_recipients
    feedback_submission.notification_recipients(except: author).find_each do |user|
      Notification.create!(user: user, event: self)
      CommentMailer.new_comment(user, self).deliver_later
    end
  end

  def broadcast_comment
    broadcast_append_to "feedback_submission_comments:#{feedback_submission_id}",
      target: "comments_list_#{feedback_submission_id}",
      html: ApplicationController.render(Comments::CommentComponent.new(comment: self), layout: false)
  end
end
