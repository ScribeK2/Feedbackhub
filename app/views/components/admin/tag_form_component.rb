# frozen_string_literal: true

module Admin
  class TagFormComponent < ApplicationComponent
    def initialize(tag:, merge_targets:)
      @tag = tag
      @merge_targets = merge_targets
    end

    def view_template
      div(class: "max-w-lg mx-auto space-y-6") do
        h1(class: "page-title") { "Edit Tag" }

        Card class: "surface" do |card|
          card.body do
            render_form
          end
        end

        render_merge_card if @merge_targets.any?
      end
    end

    private

    def render_form
      form(action: admin_tag_path(@tag), method: "post", class: "space-y-4") do
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        input(type: "hidden", name: "_method", value: "patch")

        render_errors

        div(class: "form-control") do
          label(class: "label") { span(class: "label-text") { "Name" } }
          input(type: "text", name: "tag[name]", value: @tag.name,
                class: "input input-bordered w-full", required: true)
          span(class: "label-text-alt text-base-content/60 mt-1") do
            plain "Renaming applies to every article carrying this tag. Names are stored lowercase."
          end
        end

        div(class: "form-control mt-6 flex flex-row gap-2") do
          Button(:primary, type: "submit") { "Update Tag" }
          a(href: admin_tags_path, class: "btn btn-ghost") { "Cancel" }
        end
      end
    end

    def render_merge_card
      Card class: "surface" do |card|
        card.body do
          h2(class: "card-title text-lg font-bold") { "Merge" }
          p(class: "text-sm text-base-content/60 mb-2") do
            plain "Moves every article tagged #{@tag.name} to another tag, then deletes #{@tag.name}. This cannot be undone."
          end
          form(action: merge_admin_tag_path(@tag), method: "post", class: "flex gap-2 items-end") do
            input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
            div(class: "form-control flex-1") do
              label(class: "label") { span(class: "label-text text-sm") { "Merge into" } }
              select(name: "target_id", class: "select select-bordered select-sm w-full", required: true) do
                option(value: "") { "Select a tag…" }
                @merge_targets.each { |target| option(value: target.id) { target.name } }
              end
            end
            button(
              type: "submit",
              class: "btn btn-error btn-sm",
              data: { turbo_confirm: "Merge #{@tag.name}? All articles move and #{@tag.name} is deleted." }
            ) { "Merge" }
          end
        end
      end
    end

    def render_errors
      return unless @tag.errors.any?

      div(class: "alert alert-error") do
        ul do
          @tag.errors.full_messages.each { |msg| li { msg } }
        end
      end
    end
  end
end
