# frozen_string_literal: true

module Scorecards
  # The start/end date inputs shared by the scorecard index and show pages.
  # Renders fields only — each page supplies its own form and extra params.
  #
  # Deliberately not shared with the feedback index, whose equivalent carries
  # a Stimulus filter target and its own label styling; folding it in here
  # would need more configuration than the markup it replaces.
  class DateRangeFieldsComponent < ApplicationComponent
    def initialize(date_range:)
      @date_range = date_range
    end

    def view_template
      render_field("start", @date_range.begin.to_date)
      render_field("end", @date_range.end.to_date)
    end

    private

    def render_field(name, value)
      div(class: "form-control") do
        label(class: "label") { span(class: "label-text text-xs capitalize") { name } }
        input(type: "date", name: name, value: value.iso8601, class: "input input-bordered input-sm")
      end
    end
  end
end
