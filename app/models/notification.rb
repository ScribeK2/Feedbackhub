class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :comment

  validates :comment_id, uniqueness: { scope: :user_id }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_bell

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: Time.current) unless read?
  end

  private

  def broadcast_bell
    broadcast_replace_to "notifications:#{user_id}", target: "notifications_bell",
      html: ApplicationController.render(Shared::NotificationBellComponent.new(user: user), layout: false)
  end
end
