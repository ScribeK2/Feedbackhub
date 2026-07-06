# frozen_string_literal: true

require "test_helper"

class FeedbackSubscriptionTest < ActiveSupport::TestCase
  setup do
    @submission = feedback_submissions(:high_priority)
    @user = users(:regular)
  end

  test "is unique per user and submission" do
    @submission.feedback_subscriptions.create!(user: @user)
    duplicate = @submission.feedback_subscriptions.new(user: @user)
    assert_not duplicate.valid?
  end

  test "defaults to subscribed" do
    subscription = @submission.feedback_subscriptions.create!(user: @user)
    assert subscription.subscribed
  end

  test "subscribed and unsubscribed scopes partition rows" do
    on = @submission.feedback_subscriptions.create!(user: @user)
    off = @submission.feedback_subscriptions.create!(user: users(:admin), subscribed: false)
    assert_includes FeedbackSubscription.subscribed, on
    assert_not_includes FeedbackSubscription.subscribed, off
    assert_includes FeedbackSubscription.unsubscribed, off
  end
end
