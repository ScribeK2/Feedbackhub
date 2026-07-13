# frozen_string_literal: true

require "test_helper"

class Admin::ToolsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as_admin }

  test "non-admin is redirected" do
    sign_in_as_manager
    get admin_tools_path
    assert_redirected_to root_path
  end

  test "index lists tools" do
    get admin_tools_path
    assert_response :success
    assert_select "td", text: "MXToolbox"
  end

  test "new renders the form" do
    get new_admin_tool_path
    assert_response :success
  end

  test "create adds a tool" do
    assert_difference "Tool.count", 1 do
      post admin_tools_path, params: { tool: {
        name: "Nmap", url: "https://nmap.org", description: "Port scanner",
        icon_key: "magnifier", position: "9", active: "1"
      } }
    end
    assert_redirected_to admin_tools_path
    assert_equal "Nmap", Tool.order(:created_at).last.name
  end

  test "create rejects an invalid url" do
    assert_no_difference "Tool.count" do
      post admin_tools_path, params: { tool: {
        name: "Bad", url: "not-a-url", icon_key: "globe", position: "0", active: "1"
      } }
    end
    assert_response :unprocessable_entity
  end

  test "create rejects an unknown icon_key" do
    assert_no_difference "Tool.count" do
      post admin_tools_path, params: { tool: {
        name: "Bad", url: "https://example.com", icon_key: "nope", position: "0", active: "1"
      } }
    end
    assert_response :unprocessable_entity
  end

  test "update edits a tool" do
    patch admin_tool_path(tools(:mxtoolbox)), params: { tool: {
      name: "MX Toolbox", url: "https://mxtoolbox.com", icon_key: "envelope",
      position: "0", active: "1"
    } }
    assert_redirected_to admin_tools_path
    assert_equal "MX Toolbox", tools(:mxtoolbox).reload.name
  end

  test "update can deactivate a tool" do
    patch admin_tool_path(tools(:mxtoolbox)), params: { tool: {
      name: "MXToolbox", url: "https://mxtoolbox.com", icon_key: "envelope",
      position: "0", active: "0"
    } }
    assert_not tools(:mxtoolbox).reload.active
  end

  test "destroy deletes a tool" do
    assert_difference "Tool.count", -1 do
      delete admin_tool_path(tools(:retired_tool))
    end
    assert_redirected_to admin_tools_path
  end
end
