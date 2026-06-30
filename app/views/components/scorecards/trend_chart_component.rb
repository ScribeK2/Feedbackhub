# frozen_string_literal: true

module Scorecards
  # Inline-SVG bar chart of issue counts per time bucket. No JS.
  class TrendChartComponent < ApplicationComponent
    BAR_WIDTH = 24
    BAR_GAP = 8
    CHART_HEIGHT = 80

    def initialize(buckets:)
      @buckets = buckets
    end

    def view_template
      max = @buckets.map { |b| b[:count] }.max.to_i
      if max.zero?
        p(class: "text-sm text-base-content/60") { "No issues in this period." }
      else
        render_chart(max)
      end
    end

    private

    def render_chart(max)
      width = @buckets.size * (BAR_WIDTH + BAR_GAP)
      svg(viewBox: "0 0 #{width} #{CHART_HEIGHT + 20}", class: "w-full h-28 text-primary", role: "img") do |s|
        @buckets.each_with_index do |bucket, i|
          height = (bucket[:count].to_f / max * CHART_HEIGHT).round
          x = i * (BAR_WIDTH + BAR_GAP)
          s.rect(x: x, y: CHART_HEIGHT - height, width: BAR_WIDTH, height: height, rx: 2, fill: "currentColor")
          s.text(
            x: x + BAR_WIDTH / 2, y: CHART_HEIGHT + 14,
            "text-anchor": "middle", fill: "currentColor",
            class: "text-[8px] opacity-60"
          ) { bucket[:label] }
        end
      end
    end
  end
end
