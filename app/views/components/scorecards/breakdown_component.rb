# frozen_string_literal: true

module Scorecards
  # A titled list of "label — bar — count" rows. Reused for severity,
  # category, and impact breakdowns. `counts` is an ordered Hash.
  class BreakdownComponent < ApplicationComponent
    def initialize(title:, counts:)
      @title = title
      @counts = counts
    end

    def view_template
      Card class: "surface" do |card|
        card.body do
          h3(class: "card-title text-sm font-bold mb-3") { @title }
          if @counts.values.sum.zero?
            p(class: "text-sm text-base-content/60") { "None in this period." }
          else
            div(class: "space-y-2") do
              max = @counts.values.max
              @counts.each { |label, count| render_row(label, count, max) }
            end
          end
        end
      end
    end

    private

    def render_row(label, count, max)
      pct = max.zero? ? 0 : (count.to_f / max * 100).round
      div(class: "flex items-center gap-2 text-sm") do
        span(class: "w-32 shrink-0 truncate") { label }
        div(class: "flex-1 bg-base-200 rounded h-3 overflow-hidden") do
          div(class: "bg-primary h-3 rounded", style: "width: #{pct}%")
        end
        span(class: "w-6 text-right tabular-nums") { count.to_s }
      end
    end
  end
end
