# frozen_string_literal: true

require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get settings_subscriptions_path
    assert_redirected_to login_path
  end

  test "subscriptions lists only the user's subscribed feedbacks" do
    submission = feedback_submissions(:high_priority)
    other = feedback_submissions(:low_priority)
    submission.feedback_subscriptions.create!(user: users(:regular))
    other.feedback_subscriptions.create!(user: users(:regular), subscribed: false)

    sign_in_as_user
    get settings_subscriptions_path
    assert_response :success
    assert_match "TK-001", response.body
    assert_no_match "TK-002", response.body
  end

  test "subscriptions shows an empty state" do
    sign_in_as_user
    get settings_subscriptions_path
    assert_response :success
    assert_match "No subscriptions", response.body
  end

  test "subscriptions page shows settings tabs" do
    sign_in_as_user
    get settings_subscriptions_path
    assert_response :success
    assert_select "a.tab", text: "Account"
    assert_select "a.tab.tab-active", text: "Subscriptions"
  end

  test "account requires authentication" do
    get settings_account_path
    assert_redirected_to login_path
  end

  test "account renders profile and password forms with account tab active" do
    sign_in_as_user
    get settings_account_path
    assert_response :success
    assert_select "a.tab.tab-active", text: "Account"
    assert_select "input[name='user[name]'][value=?]", users(:regular).name
    assert_select "input[name='user[email]'][value=?]", users(:regular).email
    assert_select "input[name='user[current_password]']"
    assert_select "input[name='user[password]']"
    assert_select "input[name='user[password_confirmation]']"
  end

  test "update_profile changes name and email" do
    sign_in_as_user
    patch settings_profile_path, params: { user: { name: "New Name", email: "newemail@test.com" } }
    assert_redirected_to settings_account_path
    users(:regular).reload
    assert_equal "New Name", users(:regular).name
    assert_equal "newemail@test.com", users(:regular).email
  end

  test "update_profile with invalid email re-renders with error" do
    sign_in_as_user
    patch settings_profile_path, params: { user: { name: "New Name", email: "not-an-email" } }
    assert_response :unprocessable_entity
    assert_equal "Regular User", users(:regular).reload.name
  end

  test "update_profile with duplicate email re-renders with error" do
    sign_in_as_user
    patch settings_profile_path, params: { user: { name: "x", email: users(:admin).email } }
    assert_response :unprocessable_entity
    assert_not_equal "x", users(:regular).reload.name
  end

  test "update_profile cannot change role" do
    sign_in_as_user
    patch settings_profile_path, params: { user: { name: "x", email: "x@test.com", role: "admin" } }
    assert_equal "user", users(:regular).reload.role
  end

  test "update_password changes password with correct current password" do
    sign_in_as_user
    patch settings_password_path, params: {
      user: { current_password: "password", password: "newpassword", password_confirmation: "newpassword" }
    }
    assert_redirected_to settings_account_path
    assert users(:regular).reload.authenticate("newpassword")
    assert_not users(:regular).authenticate("password")
  end

  test "update_password rejects wrong current password" do
    sign_in_as_user
    patch settings_password_path, params: {
      user: { current_password: "wrong", password: "newpassword", password_confirmation: "newpassword" }
    }
    assert_response :unprocessable_entity
    assert_match "Current password is incorrect", response.body
    assert users(:regular).reload.authenticate("password")
  end

  test "update_password rejects confirmation mismatch" do
    sign_in_as_user
    patch settings_password_path, params: {
      user: { current_password: "password", password: "newpassword", password_confirmation: "different" }
    }
    assert_response :unprocessable_entity
    assert users(:regular).reload.authenticate("password")
  end

  test "update_password rejects too-short password" do
    sign_in_as_user
    patch settings_password_path, params: {
      user: { current_password: "password", password: "short", password_confirmation: "short" }
    }
    assert_response :unprocessable_entity
    assert users(:regular).reload.authenticate("password")
  end

  test "update_password keeps the session valid" do
    sign_in_as_user
    patch settings_password_path, params: {
      user: { current_password: "password", password: "newpassword", password_confirmation: "newpassword" }
    }
    follow_redirect!
    assert_response :success
  end

  test "user menu links to the account settings page" do
    sign_in_as_user
    get root_path
    assert_response :success
    assert_select "a[href=?]", settings_account_path, text: "Settings"
  end
end
