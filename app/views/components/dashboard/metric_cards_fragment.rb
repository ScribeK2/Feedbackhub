# frozen_string_literal: true

module Dashboard
  class MetricCardsFragment < ApplicationComponent
    def initialize(scope: FeedbackSubmission.all)
      @scope = scope
    end

    def view_template
      open_scope = @scope.open
      div(id: "metric_cards", class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4") do
        render MetricCardComponent.new(title: "Open High Priority", count: open_scope.high_priority.count,
          modifier: :error, href: feedback_index_path(status: "open", priority: "High"))
        render MetricCardComponent.new(title: "Open Medium Priority", count: open_scope.medium_priority.count,
          modifier: :warning, href: feedback_index_path(status: "open", priority: "Medium"))
        render MetricCardComponent.new(title: "Open Low Priority", count: open_scope.low_priority.count,
          modifier: :success, href: feedback_index_path(status: "open", priority: "Low"))
        render MetricCardComponent.new(title: "Open Total", count: open_scope.count,
          modifier: :info, href: feedback_index_path(status: "open"))
      end
    end
  end
end
