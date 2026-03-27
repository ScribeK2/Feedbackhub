# frozen_string_literal: true

module Dashboard
  class MetricCardsFragment < ApplicationComponent
    def view_template
      div(id: "metric_cards", class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4") do
        render MetricCardComponent.new(title: "High Priority", count: FeedbackSubmission.high_priority.count, modifier: :error)
        render MetricCardComponent.new(title: "Medium Priority", count: FeedbackSubmission.medium_priority.count, modifier: :warning)
        render MetricCardComponent.new(title: "Low Priority", count: FeedbackSubmission.low_priority.count, modifier: :success)
        render MetricCardComponent.new(title: "Total Feedbacks", count: FeedbackSubmission.count, modifier: :info)
      end
    end
  end
end
