module Shared
  class ThemeToggleComponent < ApplicationComponent
    def view_template
      div(data: { controller: "theme" }, class: "dropdown dropdown-end") do
        label(tabindex: "0", class: "btn btn-ghost btn-circle") do
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
        ul(
          tabindex: "0",
          class: "dropdown-content z-[1] menu p-2 shadow-lg bg-base-100 rounded-box w-36"
        ) do
          li do
            button(
              type: "button",
              data: { action: "click->theme#setTheme", "theme-value": "light" }
            ) { "Light" }
          end
          li do
            button(
              type: "button",
              data: { action: "click->theme#setTheme", "theme-value": "dark" }
            ) { "Dark" }
          end
          li do
            button(
              type: "button",
              data: { action: "click->theme#setTheme", "theme-value": "corporate" }
            ) { "Corporate" }
          end
          li do
            button(
              type: "button",
              data: { action: "click->theme#setTheme", "theme-value": "business" }
            ) { "Business" }
          end
        end
      end
    end
  end
end
