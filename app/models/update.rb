class Update < ApplicationRecord
  belongs_to :author, class_name: "User"
  has_rich_text :body

  validates :date, presence: true

  scope :pinned, -> { where(pinned: true) }
  scope :unpinned, -> { where(pinned: false) }
  scope :recent, -> { order(date: :desc, created_at: :desc) }

  after_create_commit :broadcast_to_dashboard

  private

  def broadcast_to_dashboard
    broadcast_prepend_to "dashboard",
      target: "recent_activity",
      html: ApplicationController.render(Dashboard::ActivityItemComponent.new(item: self, type: :update))
  end
end
