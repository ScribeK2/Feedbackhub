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
end
