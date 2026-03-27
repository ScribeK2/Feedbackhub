# frozen_string_literal: true

require "test_helper"

class FeedbackControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_user
    @template = feedback_templates(:csr_feedback)
  end

  # Index
  test "index renders feedbacks list" do
    get feedback_index_path
    assert_response :success
  end

  test "index filters by csr" do
    get feedback_index_path(csr: "Jane Doe")
    assert_response :success
  end

  test "index filters by submitted_by" do
    get feedback_index_path(submitted_by: "John Smith")
    assert_response :success
  end

  test "index filters by search query" do
    get feedback_index_path(q: "TK-001")
    assert_response :success
  end

  # New/Create
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

  # Show
  test "show renders submission modal" do
    submission = feedback_submissions(:high_priority)
    get feedback_path(submission)
    assert_response :success
  end

  # Form
  test "form action returns turbo stream with template fields" do
    get form_feedback_index_path(template_id: @template.id), as: :turbo_stream
    assert_response :success
  end

  test "form action without template_id shows placeholder" do
    get form_feedback_index_path, as: :turbo_stream
    assert_response :success
  end

  # Auth
  test "unauthenticated user is redirected to login" do
    delete logout_path
    get feedback_index_path
    assert_redirected_to login_path
  end
end
