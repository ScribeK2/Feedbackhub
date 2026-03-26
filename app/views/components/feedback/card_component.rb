# frozen_string_literal: true

module Feedback
  class CardComponent < ApplicationComponent
    def initialize(submission:)
      @submission = submission
    end

    def view_template
      Card as: :div,
        class: "bg-base-100/80 backdrop-blur-md shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer",
        style: "view-transition-name: card-#{@submission.id}",
        data: { action: "click->modal#open", modal_id_param: "submission-#{@submission.id}" } do |card|
        card.body class: "p-4" do
          render_header
          render_preview
          render_footer
        end

        render_popover
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-start mb-2") do
        h3(class: "card-title text-sm font-semibold") do
          plain @submission.feedback_template.name
        end
        Badge priority_modifier, :sm do
          plain @submission.data["priority"] || "—"
        end
      end
    end

    def render_preview
      div(class: "text-sm text-base-content/70 line-clamp-2 mb-3") do
        if @submission.data["feedback_type"]
          plain @submission.data["feedback_type"]
        end
      end
    end

    def render_footer
      div(class: "flex justify-between items-center text-xs text-base-content/50") do
        span { "Ticket: #{@submission.data['ticket_number'] || '—'}" }
        span { time_ago_in_words(@submission.created_at) + " ago" }
      end
    end

    def render_popover
      div(
        popover: "auto",
        id: "popover-#{@submission.id}",
        class: "bg-base-100 rounded-lg shadow-xl p-4 max-w-sm"
      ) do
        h4(class: "font-bold mb-2") { @submission.feedback_template.name }
        dl(class: "text-sm space-y-1") do
          @submission.data.each do |key, value|
            next if value.blank?
            dt(class: "font-semibold text-base-content/70") { key.humanize }
            dd(class: "ml-2") { value.to_s.truncate(100) }
          end
        end
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
