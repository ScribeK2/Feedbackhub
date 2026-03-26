# frozen_string_literal: true

require "test_helper"

class FeedbackControllerTest < ActionDispatch::IntegrationTest
  setup do
    @template = feedback_templates(:csr_feedback)
  end

  test "new renders feedback form" do
    get new_feedback_path
    assert_response :success
  end

  test "new with template_id preselects template" do
    get new_feedback_path(template_id: @template.id)
    assert_response :success
  end

  test "create saves valid submission and redirects" do
    assert_difference "FeedbackSubmission.count", 1 do
      post feedback_index_path, params: {
        feedback_template_id: @template.id,
        data: {
          ticket_number: "TK-100",
          csr: "Test CSR",
          feedback_type: "Knowledge Gap",
          impact: "Resolution Time",
          priority: "High",
          submitted_by: "Tester"
        }
      }
    end
    assert_redirected_to hub_path
  end

  test "create via turbo stream returns success component" do
    post feedback_index_path, params: {
      feedback_template_id: @template.id,
      data: {
        ticket_number: "TK-101",
        csr: "CSR",
        feedback_type: "Other",
        impact: "Other",
        priority: "Low",
        submitted_by: "Tester"
      }
    }, as: :turbo_stream
    assert_response :success
  end

  test "create with missing data re-renders form" do
    post feedback_index_path, params: {
      feedback_template_id: @template.id
    }
    assert_response :unprocessable_entity
  end

  test "show renders submission modal" do
    submission = feedback_submissions(:high_priority)
    get feedback_path(submission)
    assert_response :success
  end

  test "form action returns turbo stream with template fields" do
    get form_feedback_index_path(template_id: @template.id), as: :turbo_stream
    assert_response :success
  end

  test "form action without template_id shows placeholder" do
    get form_feedback_index_path, as: :turbo_stream
    assert_response :success
  end
end
