# frozen_string_literal: true

require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  test "valid article saves successfully" do
    article = Article.new(title: "Test Article", author: users(:admin))
    assert article.save
  end

  test "requires title" do
    article = Article.new(author: users(:admin))
    assert_not article.valid?
    assert_includes article.errors[:title], "can't be blank"
  end

  test "requires author" do
    article = Article.new(title: "Test")
    assert_not article.valid?
    assert_includes article.errors[:author], "must exist"
  end

  test "belongs to author" do
    article = articles(:dns_guide)
    assert_equal users(:admin), article.author
  end

  test "has many tags through article_tags" do
    article = articles(:dns_guide)
    assert_includes article.tags, tags(:networking)
    assert_includes article.tags, tags(:troubleshooting)
  end

  test "has rich text body" do
    article = articles(:dns_guide)
    assert_respond_to article, :body
  end

  test "search scope finds by title" do
    results = Article.search("DNS")
    assert_includes results, articles(:dns_guide)
  end

  test "search scope finds by tag name" do
    results = Article.search("networking")
    assert_includes results, articles(:dns_guide)
  end

  test "destroying article destroys article_tags" do
    article = articles(:dns_guide)
    tag_count = article.article_tags.count
    assert tag_count > 0
    assert_difference "ArticleTag.count", -tag_count do
      article.destroy
    end
  end
end
