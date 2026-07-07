# frozen_string_literal: true

module Feedback
  class TriageSectionComponent < ApplicationComponent
    def initialize(submission:, user:, failed_change: nil)
      @submission = submission
      @user = user
      @failed_change = failed_change
    end

    def view_template
      div(id: "triage_submission_#{@submission.id}", class: "mt-6 pt-5 border-t border-base-300") do
        div(class: "flex items-center justify-between mb-3") do
          p(class: "text-xs font-semibold uppercase tracking-wider text-base-content/50") { "Status" }
          render StatusBadgeComponent.new(submission: @submission)
        end
        render_error if @failed_change&.errors&.any?
        render_controls if @submission.triagable_by?(@user)
        render_timeline
      end
    end

    private

    def render_error
      div(class: "alert alert-error text-sm py-2 mb-3") do
        plain @failed_change.errors.full_messages.to_sentence
      end
    end

    def render_controls
      div(class: "flex flex-wrap gap-2 items-start") do
        case @submission.status
        when "open"
          render_one_click("reviewed", "Mark Reviewed")
          render_note_form("actioned", "Actioned")
          render_note_form("dismissed", "Dismissed")
        when "reviewed"
          render_note_form("actioned", "Actioned")
          render_note_form("dismissed", "Dismissed")
        when "actioned", "dismissed"
          render_one_click("open", "Reopen")
        end
      end
    end

    def render_one_click(to_status, label)
      form(action: feedback_status_path(@submission), method: "post") do
        input(type: "hidden", name: "_method", value: "patch")
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        input(type: "hidden", name: "to_status", value: to_status)
        button(type: "submit", class: "btn btn-ghost btn-sm") { label }
      end
    end

    def render_note_form(to_status, label)
      details(class: "dropdown") do
        summary(class: "btn btn-sm #{to_status == 'actioned' ? 'btn-success btn-soft' : 'btn-ghost'}") do
          plain label
        end
        div(class: "dropdown-content bg-base-100 rounded-box z-10 w-72 p-3 shadow") do
          form(action: feedback_status_path(@submission), method: "post", class: "space-y-2") do
            input(type: "hidden", name: "_method", value: "patch")
            input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
            input(type: "hidden", name: "to_status", value: to_status)
            textarea(
              name: "note", required: true, rows: 2,
              placeholder: "What was done? (required)",
              class: "textarea textarea-bordered textarea-sm w-full"
            )
            button(type: "submit", class: "btn btn-primary btn-sm") { "Confirm #{label.downcase}" }
          end
        end
      end
    end

    def render_timeline
      changes = @submission.status_changes.chronological.includes(:actor)
      return if changes.empty?

      ul(class: "mt-4 space-y-1") do
        changes.each { |change| render_timeline_entry(change) }
      end
    end

    def render_timeline_entry(change)
      li(class: "text-xs text-base-content/60") do
        span(class: "font-medium text-base-content/80") { change.actor.name }
        plain " #{change.verb}"
        if change.note.present?
          plain " · "
          span(class: "italic") { change.note }
        end
        plain " · #{time_ago_in_words(change.created_at)} ago"
      end
    end
  end
end
