# frozen_string_literal: true

require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @submission = feedback_submissions(:high_priority)
    @comment = @submission.comments.create!(author: users(:regular), body: "For the manager")
    @notification = Notification.find_by!(event: @comment, user: users(:manager))
  end

  test "requires authentication" do
    get notifications_path
    assert_redirected_to login_path
  end

  test "index lists the user's notifications" do
    sign_in_as_manager
    get notifications_path
    assert_response :success
    assert_match "For the manager", response.body
  end

  test "show marks the notification read and redirects to the feedback" do
    sign_in_as_manager
    get notification_path(@notification)
    assert_redirected_to feedback_path(@submission)
    assert @notification.reload.read?
  end

  test "show scopes notifications to the current user" do
    sign_in_as_user
    get notification_path(@notification)
    assert_response :not_found
  end

  test "mark_all_read clears unread notifications" do
    sign_in_as_manager
    post mark_all_read_notifications_path
    assert_empty users(:manager).notifications.unread
  end
end
