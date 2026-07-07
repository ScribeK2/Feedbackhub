# frozen_string_literal: true

module Dashboard
  class IndexComponent < ApplicationComponent
    include Phlex::Rails::Helpers::TurboStreamFrom

    def initialize(scope:, recent_activity:)
      @scope = scope
      @recent_activity = recent_activity
    end

    def view_template
      turbo_stream_from(current_user&.stream_for("dashboard") || "dashboard")

      div(class: "space-y-8") do
        render_header
        render_metric_cards
        render_activity_feed
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-center") do
        h1(class: "page-title") { "Dashboard" }
        Button(:primary, as: :a, href: new_feedback_path) { "Submit Feedback" }
      end
    end

    def render_metric_cards
      render MetricCardsFragment.new(scope: @scope)
    end

    def render_activity_feed
      render ActivityFeedComponent.new(items: @recent_activity)
    end
  end
end
