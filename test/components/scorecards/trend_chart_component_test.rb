# frozen_string_literal: true

require "test_helper"

class Scorecards::TrendChartComponentTest < ActiveSupport::TestCase
  test "renders one CSS bar per bucket with proportional heights when there are issues" do
    html = Scorecards::TrendChartComponent.new(
      buckets: [ { label: "6/1", count: 2 }, { label: "6/8", count: 0 }, { label: "6/15", count: 3 } ]
    ).call
    # One bar element per bucket (including the zero-count bucket).
    assert_equal 3, html.scan("bg-primary").size
    # Heights are inline percentages relative to the tallest bucket (count 3).
    assert_includes html, "height: 100%" # the count-3 bucket
    assert_includes html, "height: 67%"  # the count-2 bucket (2/3)
    assert_includes html, "height: 0%"   # the empty bucket
    # Every bucket label is shown.
    assert_includes html, "6/1"
    assert_includes html, "6/15"
    # No stretched SVG (the cause of the previous magnification bug).
    assert_not_includes html, "<svg"
  end

  test "renders an empty-state message when all buckets are zero" do
    html = Scorecards::TrendChartComponent.new(
      buckets: [ { label: "6/1", count: 0 }, { label: "6/8", count: 0 } ]
    ).call
    assert_not_includes html, "bg-primary"
    assert_includes html, "No issues"
  end
end
