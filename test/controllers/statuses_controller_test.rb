# frozen_string_literal: true

require "test_helper"

class StatusesControllerTest < ActionDispatch::IntegrationTest
  TURBO_STREAM = { "Accept" => "text/vnd.turbo-stream.html" }.freeze

  setup do
    @submission = feedback_submissions(:high_priority) # CSR "Jane Doe", on manager's team
  end

  test "requires authentication" do
    patch feedback_status_path(@submission), params: { to_status: "reviewed" }
    assert_redirected_to login_path
    assert_equal "open", @submission.reload.status
  end

  test "regular users cannot triage" do
    sign_in_as_user
    patch feedback_status_path(@submission), params: { to_status: "reviewed" }
    assert_redirected_to feedback_index_path
    assert_equal "open", @submission.reload.status
  end

  test "off-team managers cannot triage" do
    off_team = User.create!(email: "other-manager@test.com", name: "Other Manager",
                            password: "password", role: "manager")
    sign_in(off_team)
    patch feedback_status_path(@submission), params: { to_status: "reviewed" }
    assert_redirected_to feedback_index_path
    assert_equal "open", @submission.reload.status
  end

  test "team managers can mark feedback reviewed" do
    sign_in_as_manager
    patch feedback_status_path(@submission), params: { to_status: "reviewed" }
    assert_redirected_to feedback_path(@submission)
    assert_equal "reviewed", @submission.reload.status

    change = @submission.status_changes.last
    assert_equal users(:manager), change.actor
    assert_equal "open", change.from_status
  end

  test "admins can triage any submission" do
    sign_in_as_admin
    patch feedback_status_path(feedback_submissions(:simple_submission)), params: { to_status: "reviewed" }
    assert_equal "reviewed", feedback_submissions(:simple_submission).reload.status
  end

  test "actioning without a note is rejected" do
    sign_in_as_manager
    patch feedback_status_path(@submission), params: { to_status: "actioned" }, headers: TURBO_STREAM
    assert_response :unprocessable_entity
    assert_equal "open", @submission.reload.status
  end

  test "actioning with a note records the resolution" do
    sign_in_as_manager
    patch feedback_status_path(@submission), params: { to_status: "actioned", note: "Coached on call handling" }
    assert_equal "actioned", @submission.reload.status
    assert_equal "Coached on call handling", @submission.status_changes.last.note
  end

  test "closed feedback can be reopened" do
    sign_in_as_manager
    @submission.transition_to("actioned", actor: users(:manager), note: "done")

    patch feedback_status_path(@submission), params: { to_status: "open" }
    assert_equal "open", @submission.reload.status
  end

  test "illegal transitions are rejected" do
    sign_in_as_manager
    patch feedback_status_path(@submission), params: { to_status: "open" }, headers: TURBO_STREAM
    assert_response :unprocessable_entity
    assert_equal "open", @submission.reload.status
  end

  test "turbo stream success replaces the triage section and badge" do
    sign_in_as_manager
    patch feedback_status_path(@submission), params: { to_status: "reviewed" }, headers: TURBO_STREAM
    assert_response :success
    assert_match "triage_submission_#{@submission.id}", response.body
    assert_match "submission_status_badge_#{@submission.id}", response.body
  end
end
