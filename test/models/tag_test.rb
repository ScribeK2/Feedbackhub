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

  test "normalizes name to stripped lowercase" do
    tag = Tag.create!(name: "  Mixed Case  ")
    assert_equal "mixed case", tag.name
  end

  test "rejects a duplicate that differs only in case" do
    tag = Tag.new(name: "NETWORKING")
    assert_not tag.valid?
    assert_includes tag.errors[:name], "has already been taken"
  end

  test "merge_into! repoints articles to the target" do
    tags(:policy).merge_into!(tags(:networking))
    assert_includes articles(:policy_doc).reload.tags, tags(:networking)
    assert_not Tag.exists?(name: "policy")
  end

  test "merge_into! drops joins where the article already has the target" do
    assert_difference "ArticleTag.count", -1 do
      tags(:troubleshooting).merge_into!(tags(:networking))
    end
    assert_equal 1, articles(:dns_guide).reload.article_tags.where(tag: tags(:networking)).count
    assert_not Tag.exists?(tags(:troubleshooting).id)
  end

  test "merge_into! raises when merging into itself" do
    assert_raises(ArgumentError) do
      tags(:networking).merge_into!(tags(:networking))
    end
    assert Tag.exists?(tags(:networking).id)
  end
end
