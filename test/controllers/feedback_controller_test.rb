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

  test "manager with a team sees only team feedback" do
    FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      data: { csr: "Off Team Person", priority: "High" }
    )
    sign_in_as_manager
    get feedback_index_path
    assert_response :success
    assert_select "td a.link-primary", text: "Jane Doe", minimum: 1
    assert_select "a.link-primary", text: "Off Team Person", count: 0
  end

  test "manager cannot widen scope with csr param" do
    FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      data: { csr: "Off Team", priority: "High" }
    )
    sign_in_as_manager
    get feedback_index_path(csr: "Off Team")
    assert_response :success
    assert_select "a.link-primary", text: "Off Team", count: 0
  end

  test "index shows a status column with badges" do
    sign_in_as_user
    get feedback_index_path
    assert_response :success
    assert_select "th", text: "Status"
    assert_select "#submission_row_#{feedback_submissions(:high_priority).id} .badge", text: "Open"
  end

  test "show renders triage controls for the team manager" do
    sign_in_as_manager
    get feedback_path(feedback_submissions(:high_priority))
    assert_response :success
    assert_match "Mark Reviewed", response.body
  end

  test "show hides triage controls from regular users but keeps the status section" do
    sign_in_as_user
    get feedback_path(feedback_submissions(:high_priority))
    assert_response :success
    assert_no_match "Mark Reviewed", response.body
    assert_match "triage_submission_#{feedback_submissions(:high_priority).id}", response.body
  end

  test "show renders the status timeline" do
    submission = feedback_submissions(:high_priority)
    submission.transition_to("reviewed", actor: users(:manager))

    sign_in_as_manager
    get feedback_path(submission)
    assert_match "marked reviewed", response.body
    assert_match users(:manager).name, response.body
  end

  test "index filters by status" do
    feedback_submissions(:low_priority).update!(status: "dismissed")

    sign_in_as_user
    get feedback_index_path(status: "open")
    assert_response :success
    assert_match "TK-001", response.body
    assert_no_match "TK-002", response.body
  end

  test "index filters by priority" do
    sign_in_as_user
    get feedback_index_path(priority: "High")
    assert_response :success
    assert_match "TK-001", response.body
    assert_no_match "TK-002", response.body
  end

  test "create rejects an unregistered CSR" do
    assert_no_difference "FeedbackSubmission.count" do
      post feedback_index_path, params: {
        feedback_template_id: @template.id,
        data: {
          ticket_number: "TK-999",
          csr: "Ghost Person",
          feedback_type: "Knowledge Gap",
          impact: "Resolution Time",
          priority: "High",
          submitted_by: "Tester"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "form renders csr field as a select of active registered CSRs" do
    get new_feedback_path(template_id: @template.id)
    assert_response :success
    assert_select "select[name='data[csr]']" do
      assert_select "option[value='Jane Doe']"
      assert_select "option[value='Former Employee']", false
    end
  end
end
