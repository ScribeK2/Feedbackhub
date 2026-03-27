class FeedbackSubmission < ApplicationRecord
  belongs_to :feedback_template
  has_rich_text :feedback_details

  validates :data, presence: true

  before_save :extract_grouping_fields

  scope :by_priority, ->(p) { where(priority: p) }
  scope :high_priority, -> { where(priority: "High") }
  scope :medium_priority, -> { where(priority: "Medium") }
  scope :low_priority, -> { where(priority: "Low") }
  scope :search, ->(q) {
    where(
      "csr_name LIKE :q OR submitted_by LIKE :q OR ticket_number LIKE :q OR feedback_type LIKE :q OR data LIKE :q",
      q: "%#{sanitize_sql_like(q)}%"
    )
  }

  after_create_commit :broadcast_updates

  private

  def broadcast_updates
    broadcast_prepend_to "feedback_submissions",
      target: "submissions",
      html: ApplicationController.render(Feedback::CardComponent.new(submission: self))

    broadcast_replace_to "dashboard",
      target: "metric_cards",
      html: ApplicationController.render(Dashboard::MetricCardsFragment.new)

    broadcast_prepend_to "dashboard",
      target: "recent_activity",
      html: ApplicationController.render(Dashboard::ActivityItemComponent.new(item: self, type: :feedback))
  end

  def extract_grouping_fields
    self.csr_name = data["csr"].presence
    self.submitted_by = data["submitted_by"].presence
    self.priority = data["priority"].presence
    self.feedback_type = data["feedback_type"].presence
    self.ticket_number = data["ticket_number"].presence
  end
end
