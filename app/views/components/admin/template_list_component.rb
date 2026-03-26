module Admin
  class TemplateListComponent < ApplicationComponent
    def initialize(templates:)
      @templates = templates
    end

    def view_template
      div(class: "space-y-6") do
        render_header
        render_templates
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-center") do
        h1(class: "text-3xl font-bold") { "Feedback Templates" }
        a(href: helpers.new_admin_template_path, class: "btn btn-primary") { "New Template" }
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
      div(class: "card bg-base-100 shadow-md") do
        div(class: "card-body") do
          div(class: "flex justify-between items-start") do
            div do
              h2(class: "card-title") { template.name }
              p(class: "text-sm text-base-content/60") do
                plain "#{template.field_schema.size} fields"
              end
            end
            div(class: "flex gap-2") do
              a(
                href: helpers.edit_admin_template_path(template),
                class: "btn btn-sm btn-ghost"
              ) { "Edit" }
              button(
                type: "button",
                class: "btn btn-sm btn-ghost text-error",
                data: {
                  action: "click->modal#open",
                  modal_id_param: "delete-template-#{template.id}"
                }
              ) { "Delete" }
            end
          end

          div(class: "mt-4") do
            div(class: "flex flex-wrap gap-2") do
              template.field_schema.each do |field|
                field = field.with_indifferent_access
                span(class: "badge badge-outline badge-sm") { field[:label] }
              end
            end
          end
        end
      end

      render_delete_modal(template)
    end

    def render_delete_modal(template)
      dialog(id: "delete-template-#{template.id}", class: "modal") do
        div(class: "modal-box") do
          h3(class: "font-bold text-lg") { "Delete Template?" }
          p(class: "py-4") do
            plain "Are you sure you want to delete "
            strong { template.name }
            plain "? This action cannot be undone."
          end
          div(class: "modal-action") do
            form(method: "dialog") do
              button(class: "btn") { "Cancel" }
            end
            form(
              action: helpers.admin_template_path(template),
              method: "post"
            ) do
              input(type: "hidden", name: "_method", value: "delete")
              input(
                type: "hidden",
                name: "authenticity_token",
                value: helpers.form_authenticity_token
              )
              button(type: "submit", class: "btn btn-error") { "Delete" }
            end
          end
        end
        form(method: "dialog", class: "modal-backdrop") do
          button { "close" }
        end
      end
    end

    def render_empty_state
      div(class: "text-center py-12") do
        p(class: "text-base-content/60 text-lg") { "No templates yet." }
        a(href: helpers.new_admin_template_path, class: "btn btn-primary mt-4") do
          "Create First Template"
        end
      end
    end
  end
end
