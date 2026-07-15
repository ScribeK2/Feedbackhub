# frozen_string_literal: true

module Scorecards
  class IndexComponent < ApplicationComponent
    def initialize(tiles:)
      @tiles = tiles
    end

    def view_template
      div(class: "space-y-6") do
        div(class: "flex justify-between items-center") do
          h1(class: "page-title") { "Scorecards" }
          unless @tiles.empty?
            a(href: scorecards_path(format: :csv), class: "btn btn-ghost btn-sm",
              data: { turbo: "false" }) { "Export CSV" }
          end
        end
        if @tiles.empty?
          render_empty_prompt
        else
          div(class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4") do
            @tiles.each { |tile| render_tile(tile) }
          end
        end
      end
    end

    private

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
