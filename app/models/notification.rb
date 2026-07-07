class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :event, polymorphic: true

  validates :event_id, uniqueness: { scope: [ :user_id, :event_type ] }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_bell

  # Preloads each polymorphic event's associations needed to render headlines
  # (author/actor + feedback_submission), avoiding per-notification N+1 queries.
  def self.with_event_context
    includes(:event).load.tap do |notifications|
      events = notifications.map(&:event)
      events.group_by(&:class).each do |klass, records|
        associations = klass == Comment ? [ :author, :feedback_submission ] : [ :actor, :feedback_submission ]
        ActiveRecord::Associations::Preloader.new(records: records, associations: associations).call
      end
    end
  end

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
