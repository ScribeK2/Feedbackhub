# frozen_string_literal: true

module Scorecards
  class ShowComponent < ApplicationComponent
    def initialize(report:)
      @report = report
    end

    def view_template
      div(class: "space-y-6") do
        render_header
        render_date_form
        if @report.empty?
          render_no_data
        else
          render_volume_panel
          div(class: "grid grid-cols-1 lg:grid-cols-3 gap-4") do
            render BreakdownComponent.new(title: "Severity", counts: @report.severity_counts, href_for: index_link(:priority))
            render BreakdownComponent.new(title: "Category", counts: @report.category_counts, href_for: index_link(:feedback_type))
            render BreakdownComponent.new(title: "Follow-through", counts: @report.status_counts, href_for: index_link(:status))
            render BreakdownComponent.new(title: "Impact", counts: @report.impact_counts)
          end
          render_recent
        end
      end
    end

    private

    def render_header
      div(class: "flex items-center justify-between") do
        div do
          h1(class: "page-title") { @report.csr_name }
          p(class: "text-sm text-base-content/60") { "Scorecard" }
        end
        div(class: "flex gap-2") do
          a(href: detail_csv_href, class: "btn btn-ghost btn-sm", data: { turbo: "false" }) { "Export CSV" }
          a(href: scorecards_path, class: "btn btn-ghost btn-sm") { "All scorecards" }
        end
      end
    end

    def detail_csv_href
      scorecard_path(
        csr: @report.csr_name,
        start: @report.date_range.begin.to_date.iso8601,
        end: @report.date_range.end.to_date.iso8601,
        format: :csv
      )
    end

    def render_date_form
      form(action: scorecard_path, method: "get", class: "flex flex-wrap items-end gap-2") do
        input(type: "hidden", name: "csr", value: @report.csr_name)
        render DateRangeFieldsComponent.new(date_range: @report.date_range)
        Button(:primary, :sm, type: "submit") { "Apply" }
      end
    end

    # Deep link into the feedback index scoped to this report's CSR and
    # window plus one dimension (:priority, :status, or :feedback_type),
    # so the landing list matches the clicked count exactly.
    def index_link(param)
      ->(label) do
        feedback_index_path(
          csr: @report.csr_name,
          start: @report.date_range.begin.to_date.iso8601,
          end: @report.date_range.end.to_date.iso8601,
          param => label
        )
      end
    end

    def render_no_data
      Card class: "surface" do |card|
        card.body class: "items-center text-center" do
          p(class: "text-base-content/60") { "No feedback on record for #{@report.csr_name} yet." }
        end
      end
    end

    def render_volume_panel
      Card class: "surface" do |card|
        card.body do
          div(class: "flex items-baseline justify-between") do
            h2(class: "card-title text-lg font-bold") { "Issue volume" }
            render_delta
          end
          if @report.zero_in_period?
            p(class: "text-success font-medium mt-2") { "No issues logged this period \u{1F389}" }
          else
            p(class: "text-4xl font-bold mt-1") { @report.total_count.to_s }
          end
          div(class: "mt-4") { render TrendChartComponent.new(buckets: @report.trend_buckets) }
        end
      end
    end

    def render_delta
      delta = @report.delta
      if delta.positive?
        span(class: "badge badge-error badge-soft") { "▲ #{delta} vs previous" }
      elsif delta.negative?
        span(class: "badge badge-success badge-soft") { "▼ #{delta.abs} vs previous" }
      else
        span(class: "badge badge-ghost") { "No change vs previous" }
      end
    end

    def render_recent
      Card class: "surface" do |card|
        card.body do
          h2(class: "card-title text-lg font-bold mb-3") { "Recent issues" }
          ul(class: "space-y-2") do
            @report.recent.each { |submission| render_recent_row(submission) }
          end
        end
      end
    end

    def render_recent_row(submission)
      li do
        a(href: feedback_path(submission), class: "flex items-center justify-between p-2 rounded bg-base-200 hover:bg-base-300") do
          span(class: "font-medium") { submission.feedback_type.to_s }
          span(class: "flex items-center gap-2 text-sm text-base-content/60") do
            span { submission.priority.to_s }
            span { submission.created_at.to_date.to_fs(:long) }
          end
        end
      end
    end
  end
end
