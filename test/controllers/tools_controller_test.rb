# frozen_string_literal: true

require "test_helper"

class ToolsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as_user }

  test "index shows active tools ordered by position" do
    get tools_path
    assert_response :success
    assert_select "h2.card-title", text: "MXToolbox"
    assert_select "h2.card-title", text: "DNS Checker"
  end

  test "index excludes inactive tools" do
    get tools_path
    assert_response :success
    assert_select "h2.card-title", text: "Retired Tool", count: 0
  end

  test "unauthenticated user is redirected to login" do
    delete logout_path
    get tools_path
    assert_redirected_to login_path
  end
end
