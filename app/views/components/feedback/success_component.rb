# frozen_string_literal: true

module Feedback
  class SuccessComponent < ApplicationComponent
    def view_template
      turbo_frame_tag "feedback_form" do
        div(class: "text-center py-8") do
          render_icon
          h3(class: "text-2xl font-bold mb-2") { "Feedback Submitted!" }
          p(class: "text-base-content/60 mb-6") { "Your feedback has been recorded successfully." }
          render_actions
        end
      end
    end

    private

    def render_icon
      div(class: "text-success text-5xl mb-4") do
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          class: "h-16 w-16 mx-auto",
          fill: "none",
          viewBox: "0 0 24 24",
          stroke: "currentColor"
        ) do |s|
          s.path(
            stroke_linecap: "round",
            stroke_linejoin: "round",
            stroke_width: "2",
            d: "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
          )
        end
      end
    end

    def render_actions
      div(class: "flex justify-center gap-4") do
        Button(:primary, as: :a, href: new_feedback_path) { "Submit Another" }
        Button(:ghost, as: :a, href: hub_path) { "View Hub" }
      end
    end
  end
end
