# frozen_string_literal: true

require "test_helper"

class ToolsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_user
  end

  test "index renders tools from YAML" do
    get tools_path
    assert_response :success
  end

  test "unauthenticated user is redirected to login" do
    delete logout_path
    get tools_path
    assert_redirected_to login_path
  end
end
