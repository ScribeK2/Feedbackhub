# frozen_string_literal: true

require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "valid tag saves successfully" do
    tag = Tag.new(name: "new-tag")
    assert tag.save
  end

  test "requires name" do
    tag = Tag.new
    assert_not tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end

  test "requires unique name" do
    existing = tags(:networking)
    tag = Tag.new(name: existing.name)
    assert_not tag.valid?
    assert_includes tag.errors[:name], "has already been taken"
  end

  test "matching scope filters by partial name" do
    results = Tag.matching("net")
    assert_includes results, tags(:networking)
    assert_not_includes results, tags(:policy)
  end
end
