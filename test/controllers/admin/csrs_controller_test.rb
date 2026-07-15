# frozen_string_literal: true

require "test_helper"

class Admin::CsrsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as_admin }

  test "non-admin is redirected" do
    sign_in_as_manager
    get admin_csrs_path
    assert_redirected_to root_path
  end

  test "index lists CSRs" do
    get admin_csrs_path
    assert_response :success
    assert_select "td", text: "Jane Doe"
  end

  test "new renders the form" do
    get new_admin_csr_path
    assert_response :success
  end

  test "create registers a CSR" do
    assert_difference "Csr.count", 1 do
      post admin_csrs_path, params: { csr: { name: "Priya Patel" } }
    end
    assert_redirected_to admin_csrs_path
  end

  test "create rejects a duplicate name" do
    assert_no_difference "Csr.count" do
      post admin_csrs_path, params: { csr: { name: "jane doe" } }
    end
    assert_response :unprocessable_entity
  end

  test "update renames and rewrites references" do
    patch admin_csr_path(csrs(:jane_doe)), params: { csr: { name: "Jane A. Doe", active: "1" } }
    assert_redirected_to admin_csrs_path
    assert_equal "Jane A. Doe", feedback_submissions(:high_priority).reload.csr_name
    assert_equal "Jane A. Doe", feedback_submissions(:high_priority).data["csr"]
    assert_equal "Jane A. Doe", team_memberships(:manager_jane).reload.csr_name
  end

  test "update rejects a colliding rename" do
    patch admin_csr_path(csrs(:jane_doe)), params: { csr: { name: "Test CSR", active: "1" } }
    assert_response :unprocessable_entity
    assert_equal "Jane Doe", csrs(:jane_doe).reload.name
  end

  test "update can deactivate and link a user" do
    patch admin_csr_path(csrs(:jane_doe)),
      params: { csr: { name: "Jane Doe", active: "0", user_id: users(:regular).id } }
    csr = csrs(:jane_doe).reload
    assert_not csr.active
    assert_equal users(:regular), csr.user
  end

  test "update rejects a forged user_id" do
    patch admin_csr_path(csrs(:jane_doe)),
      params: { csr: { name: "Jane Doe", active: "1", user_id: User.maximum(:id).to_i + 1 } }
    assert_response :unprocessable_entity
    assert_nil csrs(:jane_doe).reload.user_id
  end

  test "update reports a rewrite failure instead of raising" do
    # A legacy row that no longer passes validation: the rename callback's
    # save! on it must come back as the form plus an explanatory error, not
    # as Rails' bare 422 exception page.
    feedback_submissions(:high_priority).update_column(:status, "legacy_status")

    patch admin_csr_path(csrs(:jane_doe)), params: { csr: { name: "Jane A. Doe", active: "1" } }

    assert_response :unprocessable_entity
    assert_select "div.alert-error", /existing feedback/i
    assert_select "input[name='csr[name]']"
    assert_equal "Jane Doe", csrs(:jane_doe).reload.name
    assert_equal "Jane Doe", feedback_submissions(:high_priority).reload.csr_name
  end

  test "merge reports a rewrite failure instead of raising" do
    feedback_submissions(:high_priority).update_column(:status, "legacy_status")

    post merge_admin_csr_path(csrs(:jane_doe)), params: { target_id: csrs(:test_csr).id }

    assert_not_nil flash[:alert]
    assert Csr.exists?(csrs(:jane_doe).id)
    assert_equal "Jane Doe", feedback_submissions(:high_priority).reload.csr_name
  end

  test "merge repoints references and removes the source" do
    post merge_admin_csr_path(csrs(:jane_doe)), params: { target_id: csrs(:test_csr).id }
    assert_redirected_to admin_csrs_path
    assert_equal "Test CSR", feedback_submissions(:high_priority).reload.csr_name
    assert_not Csr.exists?(csrs(:jane_doe).id)
  end

  test "merge rejects merging into itself" do
    post merge_admin_csr_path(csrs(:jane_doe)), params: { target_id: csrs(:jane_doe).id }
    assert_redirected_to edit_admin_csr_path(csrs(:jane_doe))
    assert Csr.exists?(csrs(:jane_doe).id)
  end

  test "destroy removes an unreferenced CSR" do
    assert_difference "Csr.count", -1 do
      delete admin_csr_path(csrs(:former_employee))
    end
    assert_redirected_to admin_csrs_path
  end

  test "destroy refuses a referenced CSR" do
    assert_no_difference "Csr.count" do
      delete admin_csr_path(csrs(:jane_doe))
    end
    assert_not_nil flash[:alert]
  end
end
