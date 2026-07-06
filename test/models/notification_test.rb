# frozen_string_literal: true

require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  setup do
    submission = feedback_submissions(:high_priority)
    @comment = submission.comments.create!(author: users(:regular), body: "Ping")
    @notification = Notification.find_by!(comment: @comment, user: users(:manager))
  end

  test "starts unread and mark_read! sets read_at once" do
    assert_not @notification.read?
    assert_includes Notification.unread, @notification

    @notification.mark_read!
    first_read_at = @notification.read_at
    assert @notification.read?

    @notification.mark_read!
    assert_equal first_read_at, @notification.reload.read_at
  end

  test "is unique per user and comment" do
    duplicate = Notification.new(user: users(:manager), comment: @comment)
    assert_not duplicate.valid?
  end
end
