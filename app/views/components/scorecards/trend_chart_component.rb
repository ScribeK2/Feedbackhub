# frozen_string_literal: true

module Scorecards
  # CSS bar chart of issue counts per time bucket. No JS, no SVG — bars are
  # plain divs sized with an inline height percentage so they scale with the
  # container and never depend on purgeable utility classes for their height.
  class TrendChartComponent < ApplicationComponent
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
      div(class: "flex items-stretch gap-2") do
        @buckets.each { |bucket| render_bucket(bucket, max) }
      end
    end

    def render_bucket(bucket, max)
      pct = (bucket[:count].to_f / max * 100).round
      div(class: "flex flex-1 flex-col items-center") do
        div(class: "flex h-24 w-full items-end justify-center") do
          div(
            class: "w-8 max-w-full rounded-t bg-primary",
            style: "height: #{pct}%",
            title: "#{bucket[:label]}: #{bucket[:count]}"
          )
        end
        span(class: "mt-1 text-xs opacity-60 whitespace-nowrap") { bucket[:label] }
      end
    end
  end
end
