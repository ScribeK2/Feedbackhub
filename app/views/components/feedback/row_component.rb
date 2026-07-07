# frozen_string_literal: true

module Feedback
  class RowComponent < ApplicationComponent
    def initialize(submission:)
      @submission = submission
    end

    def view_template
      tr(
        id: "submission_row_#{@submission.id}",
        class: "hover cursor-pointer",
        data: { action: "click->modal#open", modal_id_param: "submission-#{@submission.id}" }
      ) do
        td { render_priority_badge }
        td { render StatusBadgeComponent.new(submission: @submission) }
        td(class: "font-mono text-sm") { @submission.ticket_number || "—" }
        td do
          if @submission.csr_name.present?
            a(
              href: feedback_index_path(csr: @submission.csr_name),
              class: "link link-hover link-primary"
            ) { @submission.csr_name }
          else
            plain "—"
          end
        end
        td(class: "text-sm") { @submission.feedback_type || "—" }
        td do
          if @submission.submitted_by.present?
            a(
              href: feedback_index_path(submitted_by: @submission.submitted_by),
              class: "link link-hover link-primary"
            ) { @submission.submitted_by }
          else
            plain "—"
          end
        end
        td(class: "text-sm text-base-content/70") { @submission.feedback_template.name }
        td(class: "text-sm text-base-content/50") { time_ago_in_words(@submission.created_at) + " ago" }
      end
    end

    private

    def render_priority_badge
      modifier = case @submission.priority
      when "High" then :error
      when "Medium" then :warning
      when "Low" then :success
      else :ghost
      end
      Badge modifier, :sm, class: "badge-soft" do
        plain @submission.priority || "—"
      end
    end
  end
end
