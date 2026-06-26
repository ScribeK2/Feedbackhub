# frozen_string_literal: true

module Shared
  class EmptyStateComponent < ApplicationComponent
    ICONS = {
      inbox: "M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4",
      document: "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z",
      megaphone: "M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z"
    }.freeze

    def initialize(title:, description: nil, icon: :inbox)
      @title = title
      @description = description
      @icon = icon
    end

    def view_template(&block)
      div(class: "surface flex flex-col items-center justify-center text-center px-6 py-16 gap-3") do
        render_icon
        h3(class: "text-lg font-semibold") { @title }
        p(class: "text-base-content/60 max-w-sm") { @description } if @description
        div(class: "mt-2", &block) if block
      end
    end

    private

    def render_icon
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        class: "w-12 h-12 text-base-content/25",
        fill: "none",
        viewBox: "0 0 24 24",
        stroke: "currentColor",
        stroke_width: "1.5"
      ) do |s|
        s.path(stroke_linecap: "round", stroke_linejoin: "round", d: ICONS.fetch(@icon, ICONS[:inbox]))
      end
    end
  end
end
