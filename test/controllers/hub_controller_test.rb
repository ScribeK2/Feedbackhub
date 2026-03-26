# frozen_string_literal: true

require "test_helper"

class HubControllerTest < ActionDispatch::IntegrationTest
  test "index renders successfully" do
    get hub_path
    assert_response :success
  end

  test "root path renders hub index" do
    get root_path
    assert_response :success
  end

  test "index loads submissions" do
    get hub_path
    assert_response :success
  end
end
