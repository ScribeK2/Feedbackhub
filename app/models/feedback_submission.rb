class FeedbackSubmission < ApplicationRecord
  belongs_to :feedback_template
  belongs_to :submitter, class_name: "User", optional: true
  has_many :comments, dependent: :destroy
  has_many :feedback_subscriptions, dependent: :destroy
  has_rich_text :feedback_details

  validates :data, presence: true

  before_save :extract_grouping_fields
  after_create :subscribe_submitter

  scope :by_priority, ->(p) { where(priority: p) }
  scope :high_priority, -> { where(priority: "High") }
  scope :medium_priority, -> { where(priority: "Medium") }
  scope :low_priority, -> { where(priority: "Low") }
  scope :for_csrs, ->(names) {
    names = Array(names).map { |n| n.to_s.downcase }.reject(&:blank?)
    next none if names.empty?
    where("LOWER(csr_name) IN (?)", names)
  }
  scope :search, ->(q) {
    where(
      "csr_name LIKE :q OR submitted_by LIKE :q OR ticket_number LIKE :q OR feedback_type LIKE :q OR data LIKE :q",
      q: "%#{sanitize_sql_like(q)}%"
    )
  }

  after_create_commit :broadcast_updates

  # Users notified about new comments: explicit subscribers plus managers whose
  # team includes this CSR, minus explicit opt-outs and the comment author.
  def notification_recipients(except: nil)
    ids = feedback_subscriptions.subscribed.pluck(:user_id) |
      User.managers_for(csr_name).pluck(:id)
    ids -= feedback_subscriptions.unsubscribed.pluck(:user_id)
    ids -= [ except.id ] if except
    User.where(id: ids)
  end

  # Whether a user currently receives comment notifications for this feedback.
  def subscribed?(user)
    subscription = feedback_subscriptions.find_by(user: user)
    return subscription.subscribed if subscription

    User.managers_for(csr_name).exists?(id: user.id)
  end

  private

  def subscribe_submitter
    feedback_subscriptions.create!(user: submitter) if submitter
  end

  def broadcast_updates
    card = ApplicationController.render(Feedback::CardComponent.new(submission: self), layout: false)
    activity = ApplicationController.render(Dashboard::ActivityItemComponent.new(item: self, type: :feedback), layout: false)

    # Global channels: admins, regular users, empty-team managers.
    broadcast_prepend_to "feedback_submissions", target: "submissions", html: card
    broadcast_replace_to "dashboard", target: "metric_cards",
      html: ApplicationController.render(Dashboard::MetricCardsFragment.new, layout: false)
    broadcast_prepend_to "dashboard", target: "recent_activity", html: activity

    # Per-manager channels: only managers whose team includes this CSR.
    User.managers_for(csr_name).each do |manager|
      scope = FeedbackSubmission.for_csrs(manager.team_csr_names)
      broadcast_prepend_to "feedback_submissions:#{manager.id}", target: "submissions", html: card
      broadcast_replace_to "dashboard:#{manager.id}", target: "metric_cards",
        html: ApplicationController.render(Dashboard::MetricCardsFragment.new(scope: scope), layout: false)
      broadcast_prepend_to "dashboard:#{manager.id}", target: "recent_activity", html: activity
    end
  end

  def extract_grouping_fields
    self.csr_name = data["csr"].presence
    self.submitted_by = data["submitted_by"].presence
    self.priority = data["priority"].presence
    self.feedback_type = data["feedback_type"].presence
    self.ticket_number = data["ticket_number"].presence
  end
end
