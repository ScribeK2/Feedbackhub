# frozen_string_literal: true

require "test_helper"

class UpdateTest < ActiveSupport::TestCase
  test "valid update saves successfully" do
    update = Update.new(date: Date.today, author: users(:admin))
    assert update.save
  end

  test "requires date" do
    update = Update.new(author: users(:admin))
    assert_not update.valid?
    assert_includes update.errors[:date], "can't be blank"
  end

  test "requires author" do
    update = Update.new(date: Date.today)
    assert_not update.valid?
    assert_includes update.errors[:author], "must exist"
  end

  test "defaults pinned to false" do
    update = Update.new
    assert_equal false, update.pinned
  end

  test "belongs to author" do
    update = updates(:pinned_standup)
    assert_equal users(:admin), update.author
  end

  test "has rich text body" do
    update = updates(:pinned_standup)
    assert_respond_to update, :body
  end

  test "pinned scope returns only pinned updates" do
    results = Update.pinned
    assert results.all?(&:pinned?)
    assert_includes results, updates(:pinned_standup)
    assert_not_includes results, updates(:archived_standup)
  end

  test "unpinned scope returns only unpinned updates" do
    results = Update.unpinned
    assert results.none?(&:pinned?)
    assert_includes results, updates(:archived_standup)
    assert_not_includes results, updates(:pinned_standup)
  end

  test "recent scope orders by date desc" do
    results = Update.recent
    dates = results.map(&:date)
    assert_equal dates.sort.reverse, dates
  end
end
