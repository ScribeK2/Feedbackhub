# frozen_string_literal: true

module Scorecards
  # A titled list of "label — bar — count" rows. Reused for severity,
  # category, status, and impact breakdowns. `counts` is an ordered Hash.
  # When `href_for` (a label -> URL proc) is given, rows with a positive
  # count render as links to that URL.
  class BreakdownComponent < ApplicationComponent
    def initialize(title:, counts:, href_for: nil)
      @title = title
      @counts = counts
      @href_for = href_for
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
      href = @href_for.call(label) if @href_for && count.positive?
      if href
        a(href: href, class: "#{row_classes} rounded hover:bg-base-200") { render_row_content(label, count, max) }
      else
        div(class: row_classes) { render_row_content(label, count, max) }
      end
    end

    def render_row_content(label, count, max)
      pct = max.zero? ? 0 : (count.to_f / max * 100).round
      span(class: "w-32 shrink-0 truncate") { label }
      div(class: "flex-1 bg-base-200 rounded h-3 overflow-hidden") do
        div(class: "bg-primary h-3 rounded", style: "width: #{pct}%")
      end
      span(class: "w-6 text-right tabular-nums") { count.to_s }
    end

    def row_classes
      "flex items-center gap-2 text-sm"
    end
  end
end
