module Hub
  class SubmissionModalComponent < ApplicationComponent
    def initialize(submission:)
      @submission = submission
    end

    def view_template
      dialog(
        id: "submission-#{@submission.id}",
        class: "modal",
        data: { modal_target: "dialog" }
      ) do
        div(class: "modal-box max-w-2xl bg-base-100/95 backdrop-blur-md") do
          render_header
          render_content
          render_footer
        end
        form(method: "dialog", class: "modal-backdrop") do
          button { "close" }
        end
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-start mb-4") do
        div do
          h3(class: "font-bold text-xl") { @submission.feedback_template.name }
          p(class: "text-sm text-base-content/60") do
            plain "Submitted #{helpers.time_ago_in_words(@submission.created_at)} ago"
          end
        end
        span(class: "badge #{priority_badge} badge-lg") do
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

    def render_footer
      div(class: "modal-action") do
        form(method: "dialog") do
          button(class: "btn") { "Close" }
        end
      end
    end

    def priority_badge
      case @submission.data["priority"]
      when "High"
        "badge-error"
      when "Medium"
        "badge-warning"
      when "Low"
        "badge-success"
      else
        "badge-ghost"
      end
    end
  end
end
