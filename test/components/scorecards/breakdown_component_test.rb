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
end
