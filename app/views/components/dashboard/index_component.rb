# frozen_string_literal: true

module Dashboard
  class IndexComponent < ApplicationComponent
    include Phlex::Rails::Helpers::TurboStreamFrom

    def initialize(high_count:, medium_count:, low_count:, total_count:, recent_activity:)
      @high_count = high_count
      @medium_count = medium_count
      @low_count = low_count
      @total_count = total_count
      @recent_activity = recent_activity
    end

    def view_template
      turbo_stream_from "dashboard"

      div(class: "space-y-8") do
        render_header
        render_metric_cards
        render_activity_feed
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-center") do
        h1(class: "text-3xl font-bold") { "Dashboard" }
        Button(:primary, as: :a, href: new_feedback_path) { "Submit Feedback" }
      end
    end

    def render_metric_cards
      div(id: "metric_cards", class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4") do
        render MetricCardComponent.new(title: "High Priority", count: @high_count, modifier: :error)
        render MetricCardComponent.new(title: "Medium Priority", count: @medium_count, modifier: :warning)
        render MetricCardComponent.new(title: "Low Priority", count: @low_count, modifier: :success)
        render MetricCardComponent.new(title: "Total Feedbacks", count: @total_count, modifier: :info)
      end
    end

    def render_activity_feed
      render ActivityFeedComponent.new(items: @recent_activity)
    end
  end
end
