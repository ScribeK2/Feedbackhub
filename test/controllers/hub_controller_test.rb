# frozen_string_literal: true

require "test_helper"

class HubControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_user
  end

  test "index renders dashboard successfully" do
    get hub_path
    assert_response :success
  end

  test "root path renders dashboard" do
    get root_path
    assert_response :success
  end

  test "unauthenticated user is redirected to login" do
    delete logout_path
    get hub_path
    assert_redirected_to login_path
  end

  test "recent activity feedback title links to feedback list filtered by ticket" do
    get hub_path
    assert_select "#recent_activity a[href=?]", feedback_index_path(q: "TK-001")
    assert_select "#recent_activity a[href=?]", feedback_index_path(q: "TK-002")
  end

  test "recent activity feedback without a ticket links to the plain feedback list" do
    # the simple_submission fixture has no ticket_number
    get hub_path
    assert_select "#recent_activity a[href=?]", feedback_index_path
  end

  test "recent activity article title links to the article show page" do
    get hub_path
    assert_select "#recent_activity a[href=?]", article_path(articles(:dns_guide))
    assert_select "#recent_activity a[href=?]", article_path(articles(:policy_doc))
  end

  test "recent activity update title links to the updates list" do
    get hub_path
    assert_select "#recent_activity a[href=?]", updates_path
  end

  test "recent activity titles carry the link affordance class" do
    get hub_path
    assert_select "#recent_activity a.link"
  end
end
