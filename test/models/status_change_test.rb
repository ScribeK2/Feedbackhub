# frozen_string_literal: true

require "test_helper"

class StatusChangeTest < ActiveSupport::TestCase
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
end
