# frozen_string_literal: true

require "test_helper"

class Scorecards::TrendChartComponentTest < ActiveSupport::TestCase
  test "renders an svg bar per bucket when there are issues" do
    html = Scorecards::TrendChartComponent.new(
      buckets: [ { label: "6/1", count: 2 }, { label: "6/8", count: 0 }, { label: "6/15", count: 3 } ]
    ).call
    assert_includes html, "<svg"
    assert_equal 3, html.scan("<rect").size
    assert_includes html, "6/15"
  end

  test "renders an empty-state message when all buckets are zero" do
    html = Scorecards::TrendChartComponent.new(
      buckets: [ { label: "6/1", count: 0 }, { label: "6/8", count: 0 } ]
    ).call
    assert_not_includes html, "<rect"
    assert_includes html, "No issues"
  end
end
