# frozen_string_literal: true

module Dashboard
  class MetricCardsFragment < ApplicationComponent
    def initialize(scope: FeedbackSubmission.all)
      @scope = scope
    end

    def view_template
      div(id: "metric_cards", class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4") do
        render MetricCardComponent.new(title: "High Priority", count: @scope.high_priority.count, modifier: :error)
        render MetricCardComponent.new(title: "Medium Priority", count: @scope.medium_priority.count, modifier: :warning)
        render MetricCardComponent.new(title: "Low Priority", count: @scope.low_priority.count, modifier: :success)
        render MetricCardComponent.new(title: "Total Feedbacks", count: @scope.count, modifier: :info)
      end
    end
  end
end
