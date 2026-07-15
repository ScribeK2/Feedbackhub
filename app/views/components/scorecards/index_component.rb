# frozen_string_literal: true

module Scorecards
  class IndexComponent < ApplicationComponent
    def initialize(tiles:, team:, date_range:)
      @tiles = tiles
      @team = team
      @date_range = date_range
    end

    def view_template
      div(class: "space-y-6") do
        div(class: "flex justify-between items-center") do
          h1(class: "page-title") { "Scorecards" }
          unless @tiles.empty?
            a(href: index_csv_href, class: "btn btn-ghost btn-sm",
              data: { turbo: "false" }) { "Export CSV" }
          end
        end
        if @tiles.empty?
          render_empty_prompt
        else
          render_date_form
          render_team_strip
          div(class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4") do
            @tiles.each { |tile| render_tile(tile) }
          end
        end
      end
    end

    private

    # Must carry the range: without it the export silently returns a
    # different window than the page is showing.
    def index_csv_href
      scorecards_path(
        start: @date_range.begin.to_date.iso8601,
        end: @date_range.end.to_date.iso8601,
        format: :csv
      )
    end

    def render_date_form
      form(action: scorecards_path, method: "get", class: "flex flex-wrap items-end gap-2") do
        render DateRangeFieldsComponent.new(date_range: @date_range)
        Button(:primary, :sm, type: "submit") { "Apply" }
      end
    end

    def render_empty_prompt
      Card class: "surface" do |card|
        card.body do
          p(class: "text-base-content/60") do
            plain "No CSRs on your team yet. Add CSRs on the "
            a(href: team_path, class: "link") { "My Team" }
            plain " page to see their scorecards."
          end
        end
      end
    end

    def render_team_strip
      Card class: "surface" do |card|
        card.body do
          div(class: "flex items-baseline justify-between") do
            h2(class: "card-title text-lg font-bold") { "Team total" }
            render DeltaBadgeComponent.new(delta: @team[:delta])
          end
          if @team[:zero]
            p(class: "text-success font-medium mt-2") { "No issues logged this period \u{1F389}" }
          else
            p(class: "text-4xl font-bold mt-1") { @team[:count].to_s }
          end
          div(class: "mt-4") { render TrendChartComponent.new(buckets: @team[:buckets]) }
        end
      end
    end

    def render_tile(tile)
      a(href: scorecard_path(csr: tile[:csr_name]), class: "block") do
        Card class: "surface hover:shadow-md transition-shadow" do |card|
          card.body do
            h2(class: "card-title text-base font-bold") { tile[:csr_name] }
            div(class: "flex items-baseline justify-between mt-2") do
              span(class: "text-3xl font-bold") { tile[:count].to_s }
              render_delta(tile[:delta])
            end
            p(class: "text-xs text-base-content/60 mt-1") { "issues in period" }
            if tile[:open_count].positive?
              div(class: "mt-2") do
                Badge(:info, :sm, class: "badge-soft") { "#{tile[:open_count]} open" }
              end
            end
          end
        end
      end
    end

    def render_delta(delta)
      if delta.positive?
        span(class: "text-error text-sm") { "▲ #{delta}" }
      elsif delta.negative?
        span(class: "text-success text-sm") { "▼ #{delta.abs}" }
      else
        span(class: "text-base-content/40 text-sm") { "—" }
      end
    end
  end
end
