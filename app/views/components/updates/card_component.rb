# frozen_string_literal: true

module Updates
  class CardComponent < ApplicationComponent
    def initialize(update:)
      @update = update
    end

    def view_template
      Card class: "glass-card" do |card|
        card.body do
          render_header
          render_body
          render_actions
        end
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-start mb-3") do
        div do
          div(class: "flex items-center gap-2") do
            span(class: "font-bold") { @update.date.strftime("%B %d, %Y") }
            Badge(:primary, :sm) { "Pinned" } if @update.pinned?
          end
          p(class: "text-sm text-base-content/60") do
            plain "by #{@update.author.name} — #{time_ago_in_words(@update.created_at)} ago"
          end
        end
      end
    end

    def render_body
      if @update.body.present?
        div(class: "prose max-w-none mb-4") do
          raw @update.body.to_s
        end
      end
    end

    def render_actions
      div(class: "flex gap-2") do
        render_pin_toggle
        render_delete_button if current_user&.admin?
      end
    end

    def render_pin_toggle
      form(action: update_path(@update), method: "post") do
        input(type: "hidden", name: "_method", value: "patch")
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        Button :ghost, :sm, type: "submit" do
          @update.pinned? ? "Unpin" : "Pin"
        end
      end
    end

    def render_delete_button
      form(action: update_path(@update), method: "post") do
        input(type: "hidden", name: "_method", value: "delete")
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        Button :error, :ghost, :sm, type: "submit",
          data: { turbo_confirm: "Delete this update?" } do
          "Delete"
        end
      end
    end
  end
end
