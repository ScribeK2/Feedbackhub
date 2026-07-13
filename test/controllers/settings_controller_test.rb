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
end
