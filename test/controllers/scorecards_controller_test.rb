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
end
