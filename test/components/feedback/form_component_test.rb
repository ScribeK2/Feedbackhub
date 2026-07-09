# frozen_string_literal: true

require "test_helper"

class Feedback::FormComponentTest < ActiveSupport::TestCase
  setup do
    @template = feedback_templates(:csr_feedback)
  end

  test "prefills string fields from submission data" do
    html = render_form(feedback_submissions(:high_priority))
    assert_includes html, 'value="TK-001"'
    assert_includes html, 'value="John Smith"'
  end

  test "marks the stored select option as selected" do
    html = render_form(feedback_submissions(:high_priority))
    assert_match(/<option value="Knowledge Gap" selected>/, html)
    assert_match(/<option value="High" selected>/, html)
  end

  test "shows the other input unhidden with its stored value when Other is selected" do
    submission = FeedbackSubmission.new(
      feedback_template: @template,
      data: base_data.merge("feedback_type" => "Other", "feedback_type_other" => "Tone issue")
    )
    html = render_form(submission)
    assert_match(/<option value="Other" selected>/, html)
    assert_includes html, 'value="Tone issue"'
    # The wrapper around the feedback_type _other input must not be hidden.
    # The impact field (not "Other" here) keeps its hidden wrapper, so exactly
    # one visible wrapper is expected.
    assert_includes html, '<div class="mt-2" data-other-field-target="input">'
  end

  test "keeps the other input hidden when the stored value is a regular option" do
    html = render_form(feedback_submissions(:high_priority))
    assert_not_includes html, '<div class="mt-2" data-other-field-target="input">'
    assert_includes html, '<div class="mt-2 hidden" data-other-field-target="input">'
  end

  test "includes an inactive stored CSR as a select option" do
    submission = FeedbackSubmission.new(
      feedback_template: @template,
      data: base_data.merge("csr" => "Former Employee")
    )
    html = render_form(submission)
    assert_match(/<option value="Former Employee" selected>/, html)
  end

  test "persisted submission renders in edit mode" do
    html = render_form(feedback_submissions(:high_priority))
    assert_includes html, "Edit Feedback"
    assert_includes html, "Update Feedback"
    assert_includes html, %(action="/feedback/#{feedback_submissions(:high_priority).id}")
    assert_not_includes html, "Select Template"
  end

  test "unsaved submission still renders the create form" do
    html = render_form(FeedbackSubmission.new(feedback_template: @template, data: {}))
    assert_includes html, "Submit Feedback"
    assert_includes html, 'action="/feedback"'
  end

  private

  def render_form(submission)
    ApplicationController.render(
      Feedback::FormComponent.new(
        templates: [], selected_template: @template, submission: submission
      ),
      layout: false
    )
  end

  def base_data
    {
      "ticket_number" => "TK-100",
      "csr" => "Jane Doe",
      "feedback_type" => "Knowledge Gap",
      "impact" => "Resolution Time",
      "priority" => "High",
      "submitted_by" => "Tester"
    }
  end
end
