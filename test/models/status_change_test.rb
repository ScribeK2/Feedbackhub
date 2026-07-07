# frozen_string_literal: true

require "test_helper"

class StatusChangeTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  setup do
    @submission = feedback_submissions(:high_priority)
    @manager = users(:manager)
  end

  test "one-click transition to reviewed is valid without a note" do
    change = @submission.status_changes.new(actor: @manager, from_status: "open", to_status: "reviewed")
    assert change.valid?
  end

  test "actioned requires a note" do
    change = @submission.status_changes.new(actor: @manager, from_status: "open", to_status: "actioned")
    assert_not change.valid?
    assert_includes change.errors[:note], "can't be blank"
  end

  test "dismissed requires a note" do
    change = @submission.status_changes.new(actor: @manager, from_status: "reviewed", to_status: "dismissed")
    assert_not change.valid?
    assert_includes change.errors[:note], "can't be blank"
  end

  test "reopening does not require a note" do
    change = @submission.status_changes.new(actor: @manager, from_status: "actioned", to_status: "open")
    assert change.valid?
  end

  test "rejects illegal transitions" do
    [
      %w[open open], %w[reviewed open], %w[actioned dismissed], %w[dismissed actioned]
    ].each do |from, to|
      change = @submission.status_changes.new(actor: @manager, from_status: from, to_status: to, note: "n")
      assert_not change.valid?, "expected #{from} -> #{to} to be invalid"
      assert change.errors[:to_status].any?
    end
  end

  test "rejects unknown statuses" do
    change = @submission.status_changes.new(actor: @manager, from_status: "open", to_status: "bogus")
    assert_not change.valid?
  end

  test "verb reads naturally" do
    reopen = StatusChange.new(to_status: "open")
    closed = StatusChange.new(to_status: "actioned")
    assert_equal "reopened", reopen.verb
    assert_equal "marked actioned", closed.verb
  end

  test "destroying a submission destroys its status changes" do
    @submission.status_changes.create!(actor: @manager, from_status: "open", to_status: "reviewed")
    assert_difference "StatusChange.count", -1 do
      @submission.destroy
    end
  end

  test "actioned transition notifies subscribers except the actor" do
    @submission.feedback_subscriptions.create!(user: users(:regular))

    assert_difference "Notification.count", 1 do
      assert_enqueued_emails 1 do
        @submission.transition_to("actioned", actor: @manager, note: "Coached")
      end
    end

    notification = Notification.last
    assert_equal users(:regular), notification.user
    assert_equal StatusChange.last, notification.event
  end

  test "reviewed transition does not notify" do
    @submission.feedback_subscriptions.create!(user: users(:regular))

    assert_no_difference "Notification.count" do
      assert_no_enqueued_emails do
        @submission.transition_to("reviewed", actor: @manager)
      end
    end
  end

  test "reopening notifies" do
    @submission.update!(status: "actioned")
    @submission.feedback_subscriptions.create!(user: users(:regular))

    assert_difference "Notification.count", 1 do
      @submission.transition_to("open", actor: @manager)
    end
  end

  test "notification copy reads naturally" do
    change = @submission.status_changes.create!(actor: @manager, from_status: "open",
                                                to_status: "actioned", note: "Coached")
    assert_equal "Manager User marked actioned feedback for Jane Doe", change.notification_headline
    assert_equal "Coached", change.notification_body
  end
end
