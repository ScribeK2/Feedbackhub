# frozen_string_literal: true

module Admin
  class TemplateListComponent < ApplicationComponent
    def initialize(templates:)
      @templates = templates
    end

    def view_template
      div(class: "space-y-6", data: { controller: "modal" }) do
        render_header
        render_templates
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-center") do
        h1(class: "text-3xl font-bold") { "Feedback Templates" }
        Button(:primary, as: :a, href: new_admin_template_path) { "New Template" }
      end
    end

    def render_templates
      if @templates.empty?
        render_empty_state
      else
        div(class: "grid gap-4") do
          @templates.each do |template|
            render_template_card(template)
          end
        end
      end
    end

    def render_template_card(template)
      Card :base_100, class: "shadow-md" do |card|
        card.body do
          div(class: "flex justify-between items-start") do
            div do
              card.title { template.name }
              p(class: "text-sm text-base-content/60") do
                plain "#{template.field_schema.size} fields"
              end
            end
            div(class: "flex gap-2") do
              Button(:ghost, :sm, as: :a, href: edit_admin_template_path(template)) { "Edit" }
              Button(:ghost, :sm, class: "text-error",
                data: {
                  action: "click->modal#open",
                  modal_id_param: "delete-template-#{template.id}"
                }) { "Delete" }
            end
          end

          div(class: "mt-4") do
            div(class: "flex flex-wrap gap-2") do
              template.field_schema.each do |field|
                field = field.with_indifferent_access
                Badge(:outline, :sm) { field[:label] }
              end
            end
          end
        end
      end

      render_delete_modal(template)
    end

    def render_delete_modal(template)
      Modal :tap_outside_to_close, id: "delete-template-#{template.id}" do |modal|
        modal.body do
          h3(class: "font-bold text-lg") { "Delete Template?" }
          p(class: "py-4") do
            plain "Are you sure you want to delete "
            strong { template.name }
            plain "? This action cannot be undone."
          end
          modal.action do
            modal.close_button { "Cancel" }
            form(
              action: admin_template_path(template),
              method: "post"
            ) do
              input(type: "hidden", name: "_method", value: "delete")
              input(
                type: "hidden",
                name: "authenticity_token",
                value: form_authenticity_token
              )
              Button(:error, type: :submit) { "Delete" }
            end
          end
        end
      end
    end

    def render_empty_state
      div(class: "text-center py-12") do
        p(class: "text-base-content/60 text-lg") { "No templates yet." }
        Button(:primary, as: :a, href: new_admin_template_path, class: "mt-4") do
          plain "Create First Template"
        end
      end
    end
  end
end
