# frozen_string_literal: true

module Shared
  class ThemeToggleComponent < ApplicationComponent
    THEMES = %w[light dark corporate business].freeze

    def view_template
      Dropdown :end, data: { controller: "theme" } do |dropdown|
        dropdown.button :ghost, :circle do
          render_moon_icon
        end
        dropdown.menu :base_100, class: "shadow-lg rounded-box w-36 z-[1]" do |menu|
          THEMES.each do |theme|
            menu.item do
              button(
                type: "button",
                data: { action: "click->theme#setTheme", "theme-value": theme }
              ) { theme.capitalize }
            end
          end
        end
      end
    end

    private

    def render_moon_icon
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        class: "h-5 w-5",
        fill: "none",
        viewBox: "0 0 24 24",
        stroke: "currentColor"
      ) do |s|
        s.path(
          stroke_linecap: "round",
          stroke_linejoin: "round",
          stroke_width: "2",
          d: "M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
        )
      end
    end
  end
end
