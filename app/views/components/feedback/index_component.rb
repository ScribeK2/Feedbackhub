# frozen_string_literal: true

module Feedback
  class IndexComponent < ApplicationComponent
    include Phlex::Rails::Helpers::TurboStreamFrom
    include Phlex::Rails::Helpers::TurboFrameTag

    def initialize(submissions:, filters: {})
      @submissions = submissions
      @filters = filters
    end

    def view_template
      turbo_stream_from(current_user&.stream_for("feedback_submissions") || "feedback_submissions")

      div(class: "space-y-6", data: { controller: "modal" }) do
        render_header
        render_filters
        render_submissions_list
        render_modals
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-center") do
        h1(class: "page-title") { "Feedbacks" }
        Button(:primary, as: :a, href: new_feedback_path) { "Submit Feedback" }
      end
    end

    def render_filters
      turbo_frame_tag "feedback_filters" do
        form(action: feedback_index_path, method: "get", class: "flex flex-wrap gap-3 items-end",
             data: { controller: "filter", action: "input->filter#submit" }) do
          div(class: "form-control flex-1 min-w-[200px]") do
            label(class: "label") do
              span(class: "label-text text-sm") { "Search" }
            end
            input(
              type: "search",
              name: "q",
              value: @filters[:q],
              placeholder: "Search feedbacks...",
              class: "input input-bordered input-sm w-full",
              data: { filter_target: "input" }
            )
          end

          div(class: "form-control") do
            label(class: "label") do
              span(class: "label-text text-sm") { "CSR" }
            end
            input(
              type: "text",
              name: "csr",
              value: @filters[:csr],
              placeholder: "Filter by CSR",
              class: "input input-bordered input-sm",
              data: { filter_target: "input" }
            )
          end

          div(class: "form-control") do
            label(class: "label") do
              span(class: "label-text text-sm") { "Submitted By" }
            end
            input(
              type: "text",
              name: "submitted_by",
              value: @filters[:submitted_by],
              placeholder: "Filter by submitter",
              class: "input input-bordered input-sm",
              data: { filter_target: "input" }
            )
          end

          render_filter_select("Status", "status", FeedbackSubmission::STATUSES, @filters[:status])
          render_filter_select("Priority", "priority", %w[High Medium Low], @filters[:priority])
          render_filter_select("Type", "feedback_type", feedback_type_options, @filters[:feedback_type], capitalize: false)
          render_date_filter("Start", "start", @filters[:start])
          render_date_filter("End", "end", @filters[:end])

          div(class: "form-control") do
            Button :ghost, :sm, type: "submit" do
              "Filter"
            end
          end

          if @filters.values.any?(&:present?)
            div(class: "form-control") do
              a(href: feedback_index_path, class: "btn btn-ghost btn-sm") { "Clear" }
            end
          end
        end
      end
    end

    def render_submissions_list
      if @submissions.empty?
        render_empty_state
      else
        div(class: "overflow-x-auto") do
          table(class: "table table-zebra w-full") do
            thead do
              tr do
                th { "Priority" }
                th { "Status" }
                th { "Ticket #" }
                th { "CSR" }
                th { "Type" }
                th { "Submitted By" }
                th { "Template" }
                th { "Date" }
              end
            end
            tbody(id: "submissions") do
              @submissions.each do |submission|
                render RowComponent.new(submission: submission)
              end
            end
          end
        end
      end
    end


    def render_empty_state
      render Shared::EmptyStateComponent.new(
        title: "No feedback submissions found",
        description: "Try adjusting your filters, or submit the first one."
      ) do
        Button(:primary, as: :a, href: new_feedback_path) { "Submit First Feedback" }
      end
    end

    def render_modals
      @submissions.each do |submission|
        render Hub::SubmissionModalComponent.new(submission: submission)
      end
    end

    def render_filter_select(label_text, name, values, current, capitalize: true)
      div(class: "form-control") do
        label(class: "label") do
          span(class: "label-text text-sm") { label_text }
        end
        select(name: name, class: "select select-bordered select-sm", data: { filter_target: "input" }) do
          option(value: "", selected: current.blank?) { "All" }
          values.each do |value|
            option(value: value, selected: current == value) { capitalize ? value.capitalize : value }
          end
        end
      end
    end

    def render_date_filter(label_text, name, current)
      div(class: "form-control") do
        label(class: "label") do
          span(class: "label-text text-sm") { label_text }
        end
        input(
          type: "date",
          name: name,
          value: current,
          class: "input input-bordered input-sm",
          data: { filter_target: "input" }
        )
      end
    end

    def feedback_type_options
      FeedbackSubmission.where.not(feedback_type: nil).distinct.pluck(:feedback_type).sort
    end
  end
end
