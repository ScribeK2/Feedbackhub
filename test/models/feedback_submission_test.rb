# frozen_string_literal: true

require "test_helper"

class FeedbackSubmissionTest < ActiveSupport::TestCase
  test "valid submission saves successfully" do
    template = feedback_templates(:simple_template)
    submission = FeedbackSubmission.new(
      feedback_template: template,
      data: { "comment" => "Test", "priority" => "Low" }
    )
    assert submission.save
  end

  test "requires feedback_template" do
    submission = FeedbackSubmission.new(data: { "comment" => "Test" })
    assert_not submission.valid?
    assert_includes submission.errors[:feedback_template], "must exist"
  end

  test "requires data" do
    template = feedback_templates(:simple_template)
    submission = FeedbackSubmission.new(feedback_template: template, data: nil)
    assert_not submission.valid?
    assert_includes submission.errors[:data], "can't be blank"
  end

  test "extracts csr_name from data on save" do
    template = feedback_templates(:csr_feedback)
    submission = FeedbackSubmission.create!(
      feedback_template: template,
      data: { "csr" => "Test CSR", "submitted_by" => "Someone", "ticket_number" => "TK-999", "priority" => "Low" }
    )
    assert_equal "Test CSR", submission.csr_name
  end

  test "extracts submitted_by from data on save" do
    template = feedback_templates(:csr_feedback)
    submission = FeedbackSubmission.create!(
      feedback_template: template,
      data: { "csr" => "CSR", "submitted_by" => "Reporter", "ticket_number" => "TK-999", "priority" => "Low" }
    )
    assert_equal "Reporter", submission.submitted_by
  end

  test "extracts priority from data on save" do
    template = feedback_templates(:csr_feedback)
    submission = FeedbackSubmission.create!(
      feedback_template: template,
      data: { "csr" => "CSR", "submitted_by" => "Reporter", "ticket_number" => "TK-999", "priority" => "High" }
    )
    assert_equal "High", submission.priority
  end

  test "extracts feedback_type from data on save" do
    template = feedback_templates(:csr_feedback)
    submission = FeedbackSubmission.create!(
      feedback_template: template,
      data: { "csr" => "CSR", "submitted_by" => "Reporter", "ticket_number" => "TK-999", "priority" => "Low", "feedback_type" => "Knowledge Gap" }
    )
    assert_equal "Knowledge Gap", submission.feedback_type
  end

  test "extracts ticket_number from data on save" do
    template = feedback_templates(:csr_feedback)
    submission = FeedbackSubmission.create!(
      feedback_template: template,
      data: { "csr" => "CSR", "submitted_by" => "Reporter", "ticket_number" => "TK-555", "priority" => "Low" }
    )
    assert_equal "TK-555", submission.ticket_number
  end

  test "csr_name is nil when csr not in data" do
    template = feedback_templates(:simple_template)
    submission = FeedbackSubmission.create!(
      feedback_template: template,
      data: { "comment" => "Test", "priority" => "Low" }
    )
    assert_nil submission.csr_name
  end

  test "belongs to feedback_template" do
    submission = feedback_submissions(:high_priority)
    assert_equal feedback_templates(:csr_feedback), submission.feedback_template
  end

  test "has rich text feedback_details" do
    submission = feedback_submissions(:high_priority)
    assert_respond_to submission, :feedback_details
  end

  test "data stores JSON hash" do
    submission = feedback_submissions(:high_priority)
    assert_kind_of Hash, submission.data
    assert_equal "TK-001", submission.data["ticket_number"]
  end

  # Scope tests
  test "high_priority scope returns only high priority submissions" do
    results = FeedbackSubmission.high_priority
    assert results.all? { |s| s.priority == "High" }
    assert_includes results, feedback_submissions(:high_priority)
  end

  test "low_priority scope returns only low priority submissions" do
    results = FeedbackSubmission.low_priority
    assert results.all? { |s| s.priority == "Low" }
    assert_includes results, feedback_submissions(:low_priority)
  end

  test "by_priority scope filters by given priority" do
    results = FeedbackSubmission.by_priority("High")
    assert results.all? { |s| s.priority == "High" }
  end

  test "search scope finds by csr_name" do
    results = FeedbackSubmission.search("Jane Doe")
    assert_includes results, feedback_submissions(:high_priority)
  end

  test "search scope finds by ticket_number" do
    results = FeedbackSubmission.search("TK-001")
    assert_includes results, feedback_submissions(:high_priority)
  end

  test "search scope returns empty for no match" do
    results = FeedbackSubmission.search("zzz_nonexistent_zzz")
    assert_empty results
  end

  test "for_csrs matches case-insensitively and ignores blanks" do
    assert_includes FeedbackSubmission.for_csrs([ "jane doe" ]), feedback_submissions(:high_priority)
    assert_includes FeedbackSubmission.for_csrs([ "JANE DOE" ]), feedback_submissions(:high_priority)
    assert_empty FeedbackSubmission.for_csrs([])
    assert_empty FeedbackSubmission.for_csrs(nil)
  end

  test "broadcasts to the per-manager channel for matching CSRs" do
    manager = users(:manager) # team includes "Jane Doe"
    streams = capture_turbo_stream_broadcasts("dashboard:#{manager.id}") do
      FeedbackSubmission.create!(
        feedback_template: feedback_templates(:csr_feedback),
        data: { csr: "Jane Doe", priority: "High" }
      )
    end
    assert streams.any?, "expected a broadcast to the manager's channel"
  end

  test "does not broadcast off-team feedback to the manager channel" do
    manager = users(:manager)
    streams = capture_turbo_stream_broadcasts("dashboard:#{manager.id}") do
      FeedbackSubmission.create!(
        feedback_template: feedback_templates(:csr_feedback),
        data: { csr: "Someone Else", priority: "High" }
      )
    end
    assert_empty streams
  end

  test "submission broadcast payloads are not wrapped in the application layout" do
    streams = capture_turbo_stream_broadcasts("feedback_submissions") do
      FeedbackSubmission.create!(
        feedback_template: feedback_templates(:csr_feedback),
        data: { csr: "Jane Doe", priority: "High" }
      )
    end
    assert streams.any?, "expected a submission broadcast"
    streams.each { |stream| assert_no_match(/<main/i, stream.to_html) }
  end

  test "creating a submission subscribes the submitter" do
    submission = FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      submitter: users(:regular),
      data: { csr: "Jane Doe", priority: "High" }
    )
    subscription = submission.feedback_subscriptions.find_by(user: users(:regular))
    assert subscription&.subscribed
  end

  test "notification_recipients includes explicit subscribers and team managers" do
    submission = feedback_submissions(:high_priority) # Jane Doe -> users(:manager)
    submission.feedback_subscriptions.create!(user: users(:regular))

    recipients = submission.notification_recipients
    assert_includes recipients, users(:regular)
    assert_includes recipients, users(:manager)
    assert_not_includes recipients, users(:admin)
  end

  test "notification_recipients excludes opted-out users and the excluded user" do
    submission = feedback_submissions(:high_priority)
    submission.feedback_subscriptions.create!(user: users(:regular))
    submission.feedback_subscriptions.create!(user: users(:manager), subscribed: false)

    recipients = submission.notification_recipients(except: users(:regular))
    assert_not_includes recipients, users(:manager), "opted-out manager should be excluded"
    assert_not_includes recipients, users(:regular), "excluded user should be excluded"
  end

  test "subscribed? reflects explicit rows and implicit manager interest" do
    submission = feedback_submissions(:high_priority)

    assert submission.subscribed?(users(:manager)), "team manager is implicitly subscribed"
    assert_not submission.subscribed?(users(:regular)), "no row and not a manager"

    submission.feedback_subscriptions.create!(user: users(:regular))
    assert submission.subscribed?(users(:regular))

    submission.feedback_subscriptions.create!(user: users(:manager), subscribed: false)
    assert_not submission.subscribed?(users(:manager)), "explicit opt-out beats implicit interest"
  end

  test "status defaults to open" do
    submission = FeedbackSubmission.create!(
      feedback_template: feedback_templates(:simple_template),
      data: { "comment" => "Test", "priority" => "Low" }
    )
    assert_equal "open", submission.status
  end

  test "rejects an unknown status" do
    submission = feedback_submissions(:high_priority)
    submission.status = "bogus"
    assert_not submission.valid?
    assert_includes submission.errors[:status], "is not included in the list"
  end

  test "open and closed scopes partition by status" do
    feedback_submissions(:low_priority).update!(status: "actioned")
    feedback_submissions(:simple_submission).update!(status: "dismissed")

    assert_includes FeedbackSubmission.open, feedback_submissions(:high_priority)
    assert_not_includes FeedbackSubmission.open, feedback_submissions(:low_priority)
    assert_includes FeedbackSubmission.closed, feedback_submissions(:low_priority)
    assert_includes FeedbackSubmission.closed, feedback_submissions(:simple_submission)
    assert_equal [ feedback_submissions(:low_priority) ], FeedbackSubmission.with_status("actioned").to_a
  end

  test "transition_to records a change and updates the status" do
    submission = feedback_submissions(:high_priority)
    change = submission.transition_to("reviewed", actor: users(:manager))

    assert change.persisted?
    assert_equal "reviewed", submission.reload.status
    assert_equal "open", change.from_status
    assert_equal users(:manager), change.actor
  end

  test "transition_to without a required note returns errors and leaves status unchanged" do
    submission = feedback_submissions(:high_priority)
    change = submission.transition_to("actioned", actor: users(:manager))

    assert_not change.persisted?
    assert change.errors[:note].any?
    assert_equal "open", submission.reload.status
  end

  test "transition_to rejects illegal moves" do
    submission = feedback_submissions(:high_priority)
    change = submission.transition_to("open", actor: users(:manager))

    assert_not change.persisted?
    assert_equal "open", submission.reload.status
  end

  test "status change broadcasts a row replacement to the feedback list" do
    submission = feedback_submissions(:high_priority)
    streams = capture_turbo_stream_broadcasts("feedback_submissions") do
      submission.transition_to("reviewed", actor: users(:manager))
    end
    assert streams.any? { |s| s["target"] == "submission_row_#{submission.id}" }
    assert streams.any? { |s| s["target"] == "submission_card_#{submission.id}" }
  end

  test "status change broadcasts metric cards to the global dashboard" do
    submission = feedback_submissions(:high_priority)
    streams = capture_turbo_stream_broadcasts("dashboard") do
      submission.transition_to("reviewed", actor: users(:manager))
    end
    assert streams.any? { |s| s["target"] == "metric_cards" }
  end

  test "status change broadcasts to the team manager's scoped streams" do
    submission = feedback_submissions(:high_priority)
    manager = users(:manager)
    streams = capture_turbo_stream_broadcasts("dashboard:#{manager.id}") do
      submission.transition_to("reviewed", actor: manager)
    end
    assert streams.any? { |s| s["target"] == "metric_cards" }
  end

  test "failed transitions do not broadcast" do
    submission = feedback_submissions(:high_priority)
    streams = capture_turbo_stream_broadcasts("dashboard") do
      submission.transition_to("actioned", actor: users(:manager)) # missing note
    end
    assert_empty streams
  end

  test "triagable_by? allows admins, on-team managers, and nobody else" do
    submission = feedback_submissions(:high_priority) # CSR "Jane Doe"
    off_team = User.create!(email: "other-manager@test.com", name: "Other Manager",
                            password: "password", role: "manager")

    assert submission.triagable_by?(users(:admin))
    assert submission.triagable_by?(users(:manager))
    assert_not submission.triagable_by?(off_team)
    assert_not submission.triagable_by?(users(:regular))
    assert_not submission.triagable_by?(nil)
  end

  test "canonicalizes csr casing into csr_name and data on save" do
    submission = FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      data: { "csr" => "jane doe", "priority" => "High" }
    )
    assert_equal "Jane Doe", submission.csr_name
    assert_equal "Jane Doe", submission.data["csr"]
  end

  test "rejects an unregistered csr" do
    submission = FeedbackSubmission.new(
      feedback_template: feedback_templates(:csr_feedback),
      data: { "csr" => "Ghost Person", "priority" => "High" }
    )
    assert_not submission.valid?
    assert_includes submission.errors[:base], "Ghost Person is not a registered CSR"
  end

  test "still allows submissions without a csr field" do
    submission = FeedbackSubmission.new(
      feedback_template: feedback_templates(:simple_template),
      data: { "comment" => "Nice work" }
    )
    assert submission.valid?
  end
end
