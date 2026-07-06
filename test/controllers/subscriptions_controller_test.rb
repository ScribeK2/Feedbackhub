# frozen_string_literal: true

require "test_helper"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @submission = feedback_submissions(:high_priority)
  end

  test "requires authentication" do
    patch feedback_subscription_path(@submission), params: { subscribed: "false" }
    assert_redirected_to login_path
  end

  test "update creates an opt-out row" do
    sign_in_as_user

    patch feedback_subscription_path(@submission), params: { subscribed: "false" }
    assert_redirected_to settings_subscriptions_path

    subscription = @submission.feedback_subscriptions.find_by(user: users(:regular))
    assert_not subscription.subscribed
  end

  test "update flips an existing row back to subscribed" do
    sign_in_as_user
    @submission.feedback_subscriptions.create!(user: users(:regular), subscribed: false)

    patch feedback_subscription_path(@submission), params: { subscribed: "true" }
    assert @submission.feedback_subscriptions.find_by(user: users(:regular)).subscribed
  end

  test "update responds with a turbo stream replacing the toggle" do
    sign_in_as_user

    patch feedback_subscription_path(@submission), params: { subscribed: "false" },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "subscription_toggle_#{@submission.id}", response.body
  end
end
