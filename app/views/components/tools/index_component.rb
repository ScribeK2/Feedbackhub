# frozen_string_literal: true

module Tools
  class IndexComponent < ApplicationComponent
    def initialize(tools:)
      @tools = tools
    end

    def view_template
      div(class: "space-y-6") do
        h1(class: "text-3xl font-bold") { "Tools" }
        if @tools.empty?
          p(class: "text-base-content/60 text-center py-12") { "No tools configured. Edit config/tools.yml to add tools." }
        else
          div(class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4") do
            @tools.each { |tool| render_tool_card(tool) }
          end
        end
      end
    end

    private

    def render_tool_card(tool)
      a(href: tool["url"], target: "_blank", rel: "noopener noreferrer", class: "block") do
        Card class: "glass-card hover:shadow-xl transition-all duration-300 cursor-pointer h-full" do |card|
          card.body class: "items-center text-center" do
            div(class: "mb-3") do
              render_icon(tool["icon"])
            end
            h2(class: "card-title text-lg justify-center") { tool["name"] }
            p(class: "text-sm text-base-content/60") { tool["description"] }
          end
        end
      end
    end

    def render_icon(path)
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        class: "h-10 w-10 text-primary",
        fill: "none",
        viewBox: "0 0 24 24",
        stroke: "currentColor",
        stroke_width: "1.5"
      ) do |s|
        s.path(stroke_linecap: "round", stroke_linejoin: "round", d: path)
      end
    end
  end
end
