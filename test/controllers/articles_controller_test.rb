# frozen_string_literal: true

require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_user
  end

  test "index renders articles list" do
    get articles_path
    assert_response :success
  end

  test "index filters by tag" do
    get articles_path(tag: "networking")
    assert_response :success
  end

  test "show renders article" do
    get article_path(articles(:dns_guide))
    assert_response :success
  end

  test "new renders article form" do
    get new_article_path
    assert_response :success
  end

  test "create saves valid article" do
    assert_difference "Article.count", 1 do
      post articles_path, params: {
        article: { title: "New Article", body: "Some content" },
        tag_names: "networking, new-tag"
      }
    end
    article = Article.last
    assert_redirected_to article_path(article)
    assert_equal 2, article.tags.count
  end

  test "create with blank title re-renders form" do
    assert_no_difference "Article.count" do
      post articles_path, params: {
        article: { title: "", body: "Content" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "regular user cannot delete article" do
    assert_no_difference "Article.count" do
      delete article_path(articles(:dns_guide))
    end
    assert_redirected_to root_path
  end

  test "admin can delete article" do
    delete logout_path
    sign_in_as_admin
    assert_difference "Article.count", -1 do
      delete article_path(articles(:policy_doc))
    end
    assert_redirected_to articles_path
  end

  test "unauthenticated user is redirected to login" do
    delete logout_path
    get articles_path
    assert_redirected_to login_path
  end

  test "author can edit own article" do
    get edit_article_path(articles(:policy_doc))
    assert_response :success
    assert_match "Edit Article", response.body
  end

  test "non-author cannot edit article" do
    get edit_article_path(articles(:dns_guide))
    assert_redirected_to article_path(articles(:dns_guide))
  end

  test "admin can edit any article" do
    delete logout_path
    sign_in_as_admin
    get edit_article_path(articles(:policy_doc))
    assert_response :success
  end

  test "author can update own article and retag it" do
    patch article_path(articles(:policy_doc)), params: {
      article: { title: "Updated Policy" },
      tag_names: "policy, revised"
    }
    assert_redirected_to article_path(articles(:policy_doc))
    article = articles(:policy_doc).reload
    assert_equal "Updated Policy", article.title
    assert_equal %w[policy revised].sort, article.tags.pluck(:name).sort
  end

  test "update with empty tag_names clears tags" do
    patch article_path(articles(:policy_doc)), params: {
      article: { title: "Escalation Policy" },
      tag_names: ""
    }
    assert_empty articles(:policy_doc).reload.tags
  end

  test "update with blank title re-renders form and keeps tags" do
    patch article_path(articles(:policy_doc)), params: {
      article: { title: "" },
      tag_names: "changed"
    }
    assert_response :unprocessable_entity
    article = articles(:policy_doc).reload
    assert_equal "Escalation Policy", article.title
    assert_equal %w[policy], article.tags.pluck(:name)
  end

  test "non-author cannot update article" do
    patch article_path(articles(:dns_guide)), params: { article: { title: "Hijacked" } }
    assert_redirected_to article_path(articles(:dns_guide))
    assert_equal "DNS Troubleshooting Guide", articles(:dns_guide).reload.title
  end
end
