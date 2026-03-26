# frozen_string_literal: true

module Hub
  class SubmissionModalComponent < ApplicationComponent
    def initialize(submission:)
      @submission = submission
    end

    def view_template
      Modal :tap_outside_to_close,
        id: "submission-#{@submission.id}",
        data: { modal_target: "dialog" } do |modal|
        modal.body class: "max-w-2xl bg-base-100/95 backdrop-blur-md" do
          render_header
          render_content
          render_footer(modal)
        end
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-start mb-4") do
        div do
          h3(class: "font-bold text-xl") { @submission.feedback_template.name }
          p(class: "text-sm text-base-content/60") do
            plain "Submitted #{time_ago_in_words(@submission.created_at)} ago"
          end
        end
        Badge priority_modifier, :lg do
          plain @submission.data["priority"] || "—"
        end
      end
    end

    def render_content
      div(class: "space-y-4") do
        @submission.feedback_template.field_schema.each do |field|
          field = field.with_indifferent_access
          value = @submission.data[field[:name]]
          next if value.blank? && field[:type] != "richtext"

          div(class: "border-b border-base-300 pb-3") do
            dt(class: "text-sm font-semibold text-base-content/70 mb-1") do
              plain field[:label]
            end
            dd(class: "text-base") do
              if field[:type] == "richtext"
                render_richtext_content
              else
                plain value.to_s
              end
            end
          end
        end
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
