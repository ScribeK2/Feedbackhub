# frozen_string_literal: true

require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_user
  end

  test "index returns JSON list of tags" do
    get tags_path, as: :json
    assert_response :success
    tags = JSON.parse(response.body)
    assert_kind_of Array, tags
  end

  test "index filters by query" do
    get tags_path(q: "net"), as: :json
    assert_response :success
    tags = JSON.parse(response.body)
    assert_includes tags, "networking"
    assert_not_includes tags, "policy"
  end

  test "unauthenticated user is redirected" do
    delete logout_path
    get tags_path, as: :json
    assert_response :redirect
  end
end
