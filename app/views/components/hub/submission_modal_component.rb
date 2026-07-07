# frozen_string_literal: true

module Hub
  class SubmissionModalComponent < ApplicationComponent
    def initialize(submission:, open: false)
      @submission = submission
      @open = open
    end

    def view_template
      Modal :tap_outside_to_close,
        id: "submission-#{@submission.id}",
        open: @open,
        data: { modal_target: "dialog" } do |modal|
        modal.body class: "w-11/12 max-w-4xl max-h-[calc(100vh-6rem)] p-6 sm:p-8 surface-overlay" do
          render_header
          render_content
          render_comments
          render_footer(modal)
        end
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-start gap-4 pb-5 mb-6 border-b border-base-300") do
        div do
          h3(class: "font-bold text-2xl") { @submission.feedback_template.name }
          p(class: "mt-1 text-sm text-base-content/60") do
            plain "Submitted #{time_ago_in_words(@submission.created_at)} ago"
          end
        end
        div(class: "flex items-center gap-2") do
          span(id: "submission_status_badge_#{@submission.id}") do
            render Feedback::StatusBadgeComponent.new(submission: @submission, size: :lg)
          end
          Badge priority_modifier, :lg do
            plain @submission.data["priority"] || "—"
          end
        end
      end
    end

    def render_content
      meta_fields, richtext_fields = @submission.feedback_template.field_schema
        .map(&:with_indifferent_access)
        .partition { |field| field[:type] != "richtext" }

      render_meta_grid(meta_fields)
      richtext_fields.each { |field| render_details_section(field) }
    end

    def render_meta_grid(fields)
      dl(class: "grid grid-cols-2 sm:grid-cols-3 gap-x-8 gap-y-5") do
        fields.each do |field|
          value = @submission.data[field[:name]]
          next if value.blank? || field[:name] == "priority"

          div do
            dt(class: "text-xs font-semibold uppercase tracking-wider text-base-content/50") do
              plain field[:label]
            end
            dd(class: "mt-1 text-base font-medium") { value.to_s }
          end
        end
      end
    end

    def render_details_section(field)
      div(class: "mt-6 pt-5 border-t border-base-300") do
        p(class: "text-xs font-semibold uppercase tracking-wider text-base-content/50 mb-2") do
          plain field[:label]
        end
        render_richtext_content
      end
    end

    def render_richtext_content
      if @submission.feedback_details.present?
        div(class: "prose max-w-none") do
          raw @submission.feedback_details.to_s
        end
      else
        span(class: "text-base-content/50 italic") { "No details provided" }
      end
    end

    def render_comments
      div(class: "mt-8 border-t border-base-300 pt-5") do
        turbo_frame_tag "comments_submission_#{@submission.id}",
          src: feedback_comments_path(@submission),
          loading: :lazy do
          span(class: "loading loading-dots loading-sm")
        end
      end
    end

    def render_footer(modal)
      modal.action do
        modal.close_button { "Close" }
      end
    end

    def priority_modifier
      case @submission.data["priority"]
      when "High" then :error
      when "Medium" then :warning
      when "Low" then :success
      else :ghost
      end
    end
  end
end
