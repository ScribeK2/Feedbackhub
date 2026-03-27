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
      turbo_stream_from "feedback_submissions"

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
        h1(class: "text-3xl font-bold") { "Feedbacks" }
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
                render_submission_row(submission)
              end
            end
          end
        end
      end
    end

    def render_submission_row(submission)
      tr(
        class: "hover cursor-pointer",
        data: { action: "click->modal#open", modal_id_param: "submission-#{submission.id}" }
      ) do
        td { render_priority_badge(submission) }
        td(class: "font-mono text-sm") { submission.ticket_number || "—" }
        td do
          if submission.csr_name.present?
            a(
              href: feedback_index_path(csr: submission.csr_name),
              class: "link link-hover link-primary"
            ) { submission.csr_name }
          else
            plain "—"
          end
        end
        td(class: "text-sm") { submission.feedback_type || "—" }
        td do
          if submission.submitted_by.present?
            a(
              href: feedback_index_path(submitted_by: submission.submitted_by),
              class: "link link-hover link-primary"
            ) { submission.submitted_by }
          else
            plain "—"
          end
        end
        td(class: "text-sm text-base-content/70") { submission.feedback_template.name }
        td(class: "text-sm text-base-content/50") { time_ago_in_words(submission.created_at) + " ago" }
      end
    end

    def render_priority_badge(submission)
      modifier = case submission.priority
                 when "High" then :error
                 when "Medium" then :warning
                 when "Low" then :success
                 else :ghost
      end
      Badge modifier, :sm do
        plain submission.priority || "—"
      end
    end

    def render_empty_state
      div(class: "text-center py-12") do
        p(class: "text-base-content/60 text-lg") { "No feedback submissions found." }
        Button(:primary, as: :a, href: new_feedback_path, class: "mt-4") do
          plain "Submit First Feedback"
        end
      end
    end

    def render_modals
      @submissions.each do |submission|
        render Hub::SubmissionModalComponent.new(submission: submission)
      end
    end
  end
end
