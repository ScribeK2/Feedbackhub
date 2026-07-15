# frozen_string_literal: true

module Scorecards
  # The "▲ N vs previous" badge used by the show page's volume panel and the
  # index's team strip. Index tiles use their own smaller inline treatment.
  #
  # Up is bad: every FeedbackSubmission is an issue, so more is worse.
  class DeltaBadgeComponent < ApplicationComponent
    def initialize(delta:)
      @delta = delta
    end

    def view_template
      if @delta.positive?
        span(class: "badge badge-error badge-soft") { "▲ #{@delta} vs previous" }
      elsif @delta.negative?
        span(class: "badge badge-success badge-soft") { "▼ #{@delta.abs} vs previous" }
      else
        span(class: "badge badge-ghost") { "No change vs previous" }
      end
    end
  end
end
