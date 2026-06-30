# frozen_string_literal: true

require "test_helper"

class ScorecardsControllerTest < ActionDispatch::IntegrationTest
  # The `manager` fixture's team includes "Jane Doe" (team_memberships(:manager_jane)),
  # and Jane Doe has two feedback fixtures.

  test "unauthenticated user is redirected to login" do
    get scorecards_path
    assert_redirected_to login_path
  end

  test "regular user is redirected to root" do
    sign_in_as_user
    get scorecards_path
    assert_redirected_to root_path
  end

  test "manager sees the index with their team CSR" do
    sign_in_as_manager
    get scorecards_path
    assert_response :success
    assert_includes response.body, "Jane Doe"
  end

  test "manager can view a scorecard for a CSR on their team" do
    sign_in_as_manager
    get scorecard_path(csr: "Jane Doe")
    assert_response :success
    assert_includes response.body, "Issue volume"
  end

  test "manager viewing a non-team CSR is redirected with an alert" do
    sign_in_as_manager
    get scorecard_path(csr: "Someone Else")
    assert_redirected_to scorecards_path
    assert_not_nil flash[:alert]
  end

  test "empty-team manager sees the prompt and cannot view any scorecard" do
    manager = User.create!(email: "empty@test.com", name: "Empty", password: "password", role: "manager")
    sign_in(manager)

    get scorecards_path
    assert_response :success
    assert_includes response.body, "No CSRs on your team yet"

    get scorecard_path(csr: "Jane Doe")
    assert_redirected_to scorecards_path
  end

  test "admin can view any CSR scorecard" do
    sign_in_as_admin
    get scorecard_path(csr: "Jane Doe")
    assert_response :success
    assert_includes response.body, "Issue volume"
  end

  test "viewing a CSR with no feedback at all shows the no-data state" do
    sign_in_as_admin
    get scorecard_path(csr: "Ghost CSR")
    assert_response :success
    assert_includes response.body, "No feedback on record"
  end

  test "viewing a CSR whose only issues fall outside the range shows the zero-in-period good state" do
    FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      created_at: 200.days.ago, updated_at: 200.days.ago,
      data: {
        "ticket_number" => "TK-OLD", "csr" => "Stale CSR", "feedback_type" => "Knowledge Gap",
        "impact" => "Resolution Time", "priority" => "Low", "submitted_by" => "Tester"
      }
    )
    sign_in_as_admin
    get scorecard_path(csr: "Stale CSR")
    assert_response :success
    assert_includes response.body, "No issues logged"
  end
end
