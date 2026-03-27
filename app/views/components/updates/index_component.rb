# frozen_string_literal: true

module Updates
  class IndexComponent < ApplicationComponent
    def initialize(pinned:, archived:)
      @pinned = pinned
      @archived = archived
    end

    def view_template
      div(class: "space-y-6", data: { controller: "modal" }) do
        render_header
        render_pinned_section
        render_separator
        render_archived_section
        render_new_update_modal
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-center") do
        h1(class: "text-3xl font-bold") { "Updates" }
        Button :primary, data: { action: "click->modal#open", modal_id_param: "new-update-modal" } do
          "Add New Update"
        end
      end
    end

    def render_pinned_section
      if @pinned.any?
        div(class: "space-y-4") do
          h2(class: "text-xl font-semibold flex items-center gap-2") do
            plain "Pinned"
            Badge(:primary, :sm) { @pinned.size.to_s }
          end
          @pinned.each do |update|
            render CardComponent.new(update: update)
          end
        end
      end
    end

    def render_separator
      div(class: "divider") { "Archived Updates" }
    end

    def render_archived_section
      if @archived.empty? && @pinned.empty?
        div(class: "text-center py-12") do
          p(class: "text-base-content/60 text-lg") { "No updates yet." }
        end
      elsif @archived.any?
        div(class: "space-y-4") do
          @archived.each do |update|
            render CardComponent.new(update: update)
          end
        end
      else
        p(class: "text-base-content/60 text-center py-4") { "No archived updates." }
      end
    end

    def render_new_update_modal
      render FormComponent.new
    end
  end
end
