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
end
