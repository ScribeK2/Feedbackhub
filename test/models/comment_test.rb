# frozen_string_literal: true

require "test_helper"

class CommentTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @submission = feedback_submissions(:high_priority) # csr_name "Jane Doe", manager fixture's team
    @author = users(:regular)
    @admin = users(:admin)
  end

  test "requires a body" do
    comment = @submission.comments.new(author: @author, body: "")
    assert_not comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "creating a comment subscribes the author" do
    @submission.comments.create!(author: @author, body: "First!")
    subscription = @submission.feedback_subscriptions.find_by(user: @author)
    assert subscription&.subscribed
  end

  test "commenting does not re-subscribe an explicitly unsubscribed author" do
    @submission.feedback_subscriptions.create!(user: @author, subscribed: false)
    @submission.comments.create!(author: @author, body: "Still opted out")
    assert_not @submission.feedback_subscriptions.find_by(user: @author).subscribed
  end

  test "creating a comment notifies recipients in-app and by email" do
    @submission.feedback_subscriptions.create!(user: @admin) # explicit subscriber

    comment = nil
    assert_enqueued_emails 2 do # admin (subscriber) + manager (team CSR)
      comment = @submission.comments.create!(author: @author, body: "Heads up")
    end

    recipients = Notification.where(comment: comment).map(&:user)
    assert_includes recipients, @admin
    assert_includes recipients, users(:manager)
    assert_not_includes recipients, @author
  end

  test "the comment author is not notified about their own comment" do
    @submission.feedback_subscriptions.create!(user: @author)
    comment = @submission.comments.create!(author: @author, body: "My own note")
    assert_empty Notification.where(comment: comment, user: @author)
  end

  test "comment broadcast payload is not wrapped in the application layout" do
    streams = capture_turbo_stream_broadcasts("feedback_submission_comments:#{@submission.id}") do
      @submission.comments.create!(author: @author, body: "Layout check")
    end
    assert streams.any?, "expected a comment broadcast"
    streams.each { |stream| assert_no_match(/<main/i, stream.to_html) }
  end

  test "bell broadcast payload is not wrapped in the application layout" do
    streams = capture_turbo_stream_broadcasts("notifications:#{users(:manager).id}") do
      @submission.comments.create!(author: @author, body: "Bell layout check")
    end
    assert streams.any?, "expected a bell broadcast"
    streams.each { |stream| assert_no_match(/<main/i, stream.to_html) }
  end

  test "destroying a submission destroys its comments and notifications" do
    comment = @submission.comments.create!(author: @author, body: "Ephemeral")
    assert Notification.where(comment: comment).exists?
    @submission.destroy!
    assert_not Comment.exists?(comment.id)
    assert_not Notification.where(comment_id: comment.id).exists?
  end
end
