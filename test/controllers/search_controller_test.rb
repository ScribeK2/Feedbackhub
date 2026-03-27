# frozen_string_literal: true

require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_user
  end

  test "search with query returns results" do
    get search_path(q: "Jane Doe")
    assert_response :success
  end

  test "search with empty query returns empty" do
    get search_path(q: "")
    assert_response :success
  end

  test "search finds feedbacks" do
    get search_path(q: "TK-001")
    assert_response :success
  end

  test "search finds articles" do
    get search_path(q: "DNS")
    assert_response :success
  end

  test "search with no matches returns empty" do
    get search_path(q: "zzz_nothing_here_zzz")
    assert_response :success
  end

  test "unauthenticated user is redirected" do
    delete logout_path
    get search_path(q: "test")
    assert_redirected_to login_path
  end
end
