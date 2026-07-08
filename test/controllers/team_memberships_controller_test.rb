# frozen_string_literal: true

require "test_helper"

class TeamMembershipsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as_manager }

  test "index renders for a manager" do
    get team_path
    assert_response :success
  end

  test "non-manager is redirected" do
    sign_in_as_user
    get team_path
    assert_redirected_to root_path
  end

  test "create adds a CSR to the team" do
    assert_difference "TeamMembership.count", 1 do
      post team_memberships_path, params: { csr_name: "Carlos Reyes" }
    end
    assert_redirected_to team_path
  end

  test "create rejects a duplicate CSR" do
    assert_no_difference "TeamMembership.count" do
      post team_memberships_path, params: { csr_name: "Jane Doe" }
    end
    assert_redirected_to team_path
    assert_not_nil flash[:alert]
  end

  test "create rejects a blank CSR" do
    assert_no_difference "TeamMembership.count" do
      post team_memberships_path, params: { csr_name: "" }
    end
    assert_redirected_to team_path
    assert_not_nil flash[:alert]
  end

  test "destroy removes a CSR from the team" do
    membership = team_memberships(:manager_jane)
    assert_difference "TeamMembership.count", -1 do
      delete team_membership_path(membership)
    end
    assert_redirected_to team_path
  end

  test "destroy only affects the current manager's memberships" do
    other = User.create!(email: "other@test.com", name: "Other", password: "password", role: "manager")
    foreign = other.team_memberships.create!(csr_name: "Someone")
    delete team_membership_path(foreign)
    assert_response :not_found
  end

  test "create normalizes csr casing" do
    post team_memberships_path, params: { csr_name: "carlos reyes" }
    assert_equal "Carlos Reyes", users(:manager).team_memberships.for_csr("carlos reyes").first.csr_name
  end

  test "create rejects an unregistered CSR" do
    assert_no_difference "TeamMembership.count" do
      post team_memberships_path, params: { csr_name: "Ghost Person" }
    end
    assert_redirected_to team_path
    assert_not_nil flash[:alert]
  end

  test "index offers only active unassigned CSRs" do
    get team_path
    assert_response :success
    assert_select "select[name='csr_name']" do
      assert_select "option[value='Carlos Reyes']"
      assert_select "option[value='Jane Doe']", false
      assert_select "option[value='Former Employee']", false
    end
  end
end
