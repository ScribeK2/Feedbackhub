# frozen_string_literal: true

require "test_helper"

class ToolTest < ActiveSupport::TestCase
  test "valid with name, url, and a known icon_key" do
    assert Tool.new(name: "Nmap", url: "https://nmap.org", icon_key: "magnifier").valid?
  end

  test "requires name, url, and icon_key" do
    tool = Tool.new
    assert_not tool.valid?
    assert_includes tool.errors[:name], "can't be blank"
    assert_includes tool.errors[:url], "can't be blank"
    assert_includes tool.errors[:icon_key], "can't be blank"
  end

  test "rejects a url without an http(s) scheme" do
    tool = Tool.new(name: "Bad", url: "ftp://example.com", icon_key: "globe")
    assert_not tool.valid?
    assert_includes tool.errors[:url], "must start with http:// or https://"
  end

  test "rejects an icon_key outside the curated set" do
    tool = Tool.new(name: "Bad", url: "https://example.com", icon_key: "nope")
    assert_not tool.valid?
    assert_includes tool.errors[:icon_key], "is not included in the list"
  end

  test "active scope excludes inactive tools" do
    assert_includes Tool.active, tools(:mxtoolbox)
    assert_not_includes Tool.active, tools(:retired_tool)
  end

  test "ordered scope sorts by position" do
    assert_equal [ tools(:mxtoolbox), tools(:dns_checker) ], Tool.active.ordered.to_a
  end

  test "icon_path returns the mapped svg path" do
    assert_equal Tool::ICONS["envelope"], tools(:mxtoolbox).icon_path
  end

  test "every DEFAULTS icon_key exists in ICONS" do
    Tool::DEFAULTS.each { |attrs| assert_includes Tool::ICONS.keys, attrs[:icon_key] }
  end

  test "every ICONS value is a non-empty svg path" do
    Tool::ICONS.each_value do |path|
      assert path.is_a?(String)
      assert path.start_with?("M")
    end
  end

  test "seed_defaults! creates the defaults once and is idempotent" do
    Tool.delete_all
    assert_difference "Tool.count", Tool::DEFAULTS.size do
      Tool.seed_defaults!
    end
    assert_no_difference "Tool.count" do
      Tool.seed_defaults!
    end
    mx = Tool.find_by(url: "https://mxtoolbox.com")
    assert_equal "MXToolbox", mx.name
    assert_equal 0, mx.position
  end

  test "seed_defaults! does not clobber an admin-edited tool" do
    Tool.delete_all
    Tool.seed_defaults!
    Tool.find_by(url: "https://mxtoolbox.com").update!(name: "Edited Name")

    Tool.seed_defaults!

    assert_equal "Edited Name", Tool.find_by(url: "https://mxtoolbox.com").name
  end
end
