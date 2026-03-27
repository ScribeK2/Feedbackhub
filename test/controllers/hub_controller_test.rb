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
end
