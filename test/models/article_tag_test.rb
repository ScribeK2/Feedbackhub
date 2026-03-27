# frozen_string_literal: true

require "test_helper"

class ArticleTagTest < ActiveSupport::TestCase
  test "valid article_tag saves successfully" do
    article_tag = ArticleTag.new(article: articles(:policy_doc), tag: tags(:networking))
    assert article_tag.save
  end

  test "requires article" do
    article_tag = ArticleTag.new(tag: tags(:networking))
    assert_not article_tag.valid?
  end

  test "requires tag" do
    article_tag = ArticleTag.new(article: articles(:dns_guide))
    assert_not article_tag.valid?
  end

  test "enforces uniqueness of article and tag combination" do
    existing = article_tags(:dns_networking)
    duplicate = ArticleTag.new(article: existing.article, tag: existing.tag)
    assert_not duplicate.valid?
  end
end
