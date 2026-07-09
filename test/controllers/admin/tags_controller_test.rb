# frozen_string_literal: true

require "test_helper"

class Admin::TagsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as_admin }

  test "non-admin is redirected" do
    sign_in_as_user
    get admin_tags_path
    assert_redirected_to root_path
  end

  test "index lists tags with article counts" do
    get admin_tags_path
    assert_response :success
    assert_select "td", text: "networking"
  end

  test "edit renders the form" do
    get edit_admin_tag_path(tags(:networking))
    assert_response :success
  end

  test "update renames a tag" do
    patch admin_tag_path(tags(:networking)), params: { tag: { name: "Netops" } }
    assert_redirected_to admin_tags_path
    assert_equal "netops", tags(:networking).reload.name
  end

  test "update rejects a colliding rename" do
    patch admin_tag_path(tags(:networking)), params: { tag: { name: "Troubleshooting" } }
    assert_response :unprocessable_entity
    assert_equal "networking", tags(:networking).reload.name
  end

  test "merge repoints articles and removes the source" do
    post merge_admin_tag_path(tags(:policy)), params: { target_id: tags(:networking).id }
    assert_redirected_to admin_tags_path
    assert_includes articles(:policy_doc).reload.tags, tags(:networking)
    assert_not Tag.exists?(tags(:policy).id)
  end

  test "merge rejects merging into itself" do
    post merge_admin_tag_path(tags(:policy)), params: { target_id: tags(:policy).id }
    assert_redirected_to edit_admin_tag_path(tags(:policy))
    assert Tag.exists?(tags(:policy).id)
  end

  test "destroy removes the tag and its joins" do
    assert_difference [ "Tag.count", "ArticleTag.count" ], -1 do
      delete admin_tag_path(tags(:policy))
    end
    assert_redirected_to admin_tags_path
  end

  test "non-admin cannot mutate tags" do
    sign_in_as_manager
    patch admin_tag_path(tags(:networking)), params: { tag: { name: "nope" } }
    assert_redirected_to root_path
    assert_equal "networking", tags(:networking).reload.name
  end
end
