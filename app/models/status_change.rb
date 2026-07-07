class StatusChange < ApplicationRecord
  ALLOWED_TRANSITIONS = {
    "open" => %w[reviewed actioned dismissed],
    "reviewed" => %w[actioned dismissed],
    "actioned" => %w[open],
    "dismissed" => %w[open]
  }.freeze
  NOTE_REQUIRED_STATUSES = %w[actioned dismissed].freeze

  belongs_to :feedback_submission
  belongs_to :actor, class_name: "User"

  validates :from_status, :to_status, presence: true, inclusion: { in: FeedbackSubmission::STATUSES }
  validates :note, presence: true, if: -> { NOTE_REQUIRED_STATUSES.include?(to_status) }
  validate :transition_allowed

  scope :chronological, -> { order(created_at: :asc) }

  # "reopened" | "marked reviewed" | "marked actioned" | "marked dismissed"
  def verb
    to_status == "open" ? "reopened" : "marked #{to_status}"
  end

  private

  def transition_allowed
    return if from_status.blank? || to_status.blank?
    return if ALLOWED_TRANSITIONS.fetch(from_status, []).include?(to_status)

    errors.add(:to_status, "cannot change from #{from_status} to #{to_status}")
  end
end
