class FeedbackSubmission < ApplicationRecord
  include SearchIndexable

  STATUSES = %w[open reviewed actioned dismissed].freeze
  CLOSED_STATUSES = %w[actioned dismissed].freeze

  belongs_to :feedback_template
  belongs_to :submitter, class_name: "User", optional: true
  has_many :comments, dependent: :destroy
  has_many :status_changes, dependent: :destroy
  has_many :feedback_subscriptions, dependent: :destroy
  has_rich_text :feedback_details

  validates :data, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :csr_must_be_registered

  before_save :extract_grouping_fields
  after_create :subscribe_submitter

  scope :by_priority, ->(p) { where(priority: p) }
  scope :by_feedback_type, ->(t) { where(feedback_type: t) }
  scope :high_priority, -> { where(priority: "High") }
  scope :medium_priority, -> { where(priority: "Medium") }
  scope :low_priority, -> { where(priority: "Low") }
  scope :for_csrs, ->(names) {
    names = Array(names).map { |n| n.to_s.downcase }.reject(&:blank?)
    next none if names.empty?
    where("LOWER(csr_name) IN (?)", names)
  }
  scope :search, ->(q) {
    where(id: SearchEntry.matching(q, parent_type: "FeedbackSubmission").select(:parent_id))
  }

  # Kernel#open makes `scope :open` trip Active Record's dangerous-name guard,
  # so these two are plain class methods.
  def self.open
    where(status: "open")
  end

  def self.closed
    where(status: CLOSED_STATUSES)
  end

  scope :with_status, ->(status) { where(status: status) }

  after_create_commit :broadcast_updates
  after_destroy_commit :broadcast_removal

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

  # Records a status transition and updates the denormalized status column.
  # Returns the StatusChange — persisted on success, carrying errors on failure.
  def transition_to(new_status, actor:, note: nil)
    change = status_changes.new(actor: actor, from_status: status, to_status: new_status, note: note)
    if change.valid?
      transaction do
        change.save!
        update!(status: new_status)
      end
      broadcast_status_change
    end
    change
  end

  # Re-renders row, card, and metric cards after an admin correction. Managers
  # of the previous CSR are included so their dashboards stop counting a moved
  # item; rows they can no longer see stay until reload (accepted limitation).
  def broadcast_correction(previous_csr_name)
    row = ApplicationController.render(Feedback::RowComponent.new(submission: self), layout: false)
    card = ApplicationController.render(Feedback::CardComponent.new(submission: self), layout: false)

    each_correction_audience(previous_csr_name) do |manager, scope|
      broadcast_replace_to stream_name("feedback_submissions", manager), target: "submission_row_#{id}", html: row
      broadcast_replace_to stream_name("feedback_submissions", manager), target: "submission_card_#{id}", html: card
      broadcast_replace_to stream_name("dashboard", manager), target: "metric_cards",
        html: ApplicationController.render(Dashboard::MetricCardsFragment.new(scope: scope), layout: false)
    end
  end

  # Managers may triage feedback for CSRs on their team; admins may triage anything.
  def triagable_by?(user)
    return false unless user
    return true if user.admin?

    user.manager? && User.managers_for(csr_name).exists?(id: user.id)
  end

  # Human label for notification/mailer copy.
  def csr_label
    csr_name.presence || "a feedback submission"
  end

  def search_parent
    self
  end

  def search_content
    [
      csr_name, submitted_by, ticket_number, feedback_type,
      *data.values.map(&:to_s),
      feedback_details.to_plain_text
    ].map(&:presence).compact.join("\n")
  end

  private

  def subscribe_submitter
    feedback_subscriptions.create!(user: submitter) if submitter
  end

  # Yields once for the global streams (manager = nil) and once per manager
  # whose team includes this CSR, with that audience's submission scope.
  def each_broadcast_audience
    yield nil, FeedbackSubmission.all
    User.managers_for(csr_name).find_each do |manager|
      yield manager, FeedbackSubmission.for_csrs(manager.team_csr_names)
    end
  end

  def stream_name(base, manager)
    manager ? "#{base}:#{manager.id}" : base
  end

  # Like each_broadcast_audience, but also covers managers of the CSR the
  # submission was assigned to before a correction.
  def each_correction_audience(previous_csr_name)
    yield nil, FeedbackSubmission.all
    manager_ids = User.managers_for(csr_name).pluck(:id) |
      User.managers_for(previous_csr_name).pluck(:id)
    User.where(id: manager_ids).find_each do |manager|
      yield manager, FeedbackSubmission.for_csrs(manager.team_csr_names)
    end
  end

  def broadcast_removal
    each_broadcast_audience do |manager, scope|
      broadcast_remove_to stream_name("feedback_submissions", manager), target: "submission_row_#{id}"
      broadcast_remove_to stream_name("feedback_submissions", manager), target: "submission_card_#{id}"
      broadcast_replace_to stream_name("dashboard", manager), target: "metric_cards",
        html: ApplicationController.render(Dashboard::MetricCardsFragment.new(scope: scope), layout: false)
    end
  end

  def broadcast_updates
    card = ApplicationController.render(Feedback::CardComponent.new(submission: self), layout: false)
    activity = ApplicationController.render(Dashboard::ActivityItemComponent.new(item: self, type: :feedback), layout: false)

    each_broadcast_audience do |manager, scope|
      broadcast_prepend_to stream_name("feedback_submissions", manager), target: "submissions", html: card
      broadcast_replace_to stream_name("dashboard", manager), target: "metric_cards",
        html: ApplicationController.render(Dashboard::MetricCardsFragment.new(scope: scope), layout: false)
      broadcast_prepend_to stream_name("dashboard", manager), target: "recent_activity", html: activity
    end
  end

  def broadcast_status_change
    row = ApplicationController.render(Feedback::RowComponent.new(submission: self), layout: false)
    card = ApplicationController.render(Feedback::CardComponent.new(submission: self), layout: false)

    each_broadcast_audience do |manager, scope|
      broadcast_replace_to stream_name("feedback_submissions", manager), target: "submission_row_#{id}", html: row
      broadcast_replace_to stream_name("feedback_submissions", manager), target: "submission_card_#{id}", html: card
      broadcast_replace_to stream_name("dashboard", manager), target: "metric_cards",
        html: ApplicationController.render(Dashboard::MetricCardsFragment.new(scope: scope), layout: false)
    end
  end

  def extract_grouping_fields
    if (csr = Csr.lookup(data["csr"]))
      data["csr"] = csr.name
    end
    self.csr_name = data["csr"].presence
    self.submitted_by = data["submitted_by"].presence
    self.priority = data["priority"].presence
    self.feedback_type = data["feedback_type"].presence
    self.ticket_number = data["ticket_number"].presence
  end

  def csr_must_be_registered
    return if data.blank? || data["csr"].blank?

    errors.add(:base, "#{data['csr']} is not a registered CSR") unless Csr.lookup(data["csr"])
  end
end
