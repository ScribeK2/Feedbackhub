# frozen_string_literal: true

require "test_helper"

class Scorecards::BreakdownComponentTest < ActiveSupport::TestCase
  test "renders a labeled row per entry" do
    html = Scorecards::BreakdownComponent.new(
      title: "Severity", counts: { "High" => 2, "Medium" => 0, "Low" => 1 }
    ).call
    assert_includes html, "Severity"
    assert_includes html, "High"
    assert_includes html, "Low"
  end

  test "renders an empty state when every count is zero" do
    html = Scorecards::BreakdownComponent.new(
      title: "Category", counts: { "Knowledge Gap" => 0 }
    ).call
    assert_includes html, "None in this period"
  end

  test "rows link when href_for is given and count is positive" do
    html = Scorecards::BreakdownComponent.new(
      title: "Severity", counts: { "High" => 2, "Low" => 1 },
      href_for: ->(label) { "/feedback?priority=#{label}" }
    ).call
    assert_includes html, 'href="/feedback?priority=High"'
    assert_includes html, 'href="/feedback?priority=Low"'
  end

  test "zero-count rows do not link even with href_for" do
    html = Scorecards::BreakdownComponent.new(
      title: "Severity", counts: { "High" => 2, "Medium" => 0 },
      href_for: ->(label) { "/feedback?priority=#{label}" }
    ).call
    assert_includes html, 'href="/feedback?priority=High"'
    assert_not_includes html, 'href="/feedback?priority=Medium"'
  end

  test "no rows link without href_for" do
    html = Scorecards::BreakdownComponent.new(
      title: "Impact", counts: { "Client Experience" => 3 }
    ).call
    assert_not_includes html, "<a"
  end
end
