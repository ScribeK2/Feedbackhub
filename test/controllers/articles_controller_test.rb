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
end
