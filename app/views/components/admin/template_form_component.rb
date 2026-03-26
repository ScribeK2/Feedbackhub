module Admin
  class TemplateFormComponent < ApplicationComponent
    include Phlex::Rails::Helpers::FormWith

    def initialize(template:)
      @template = template
    end

    def view_template
      div(class: "card bg-base-100 shadow-xl max-w-4xl mx-auto") do
        div(class: "card-body") do
          h2(class: "card-title text-2xl mb-6") do
            plain @template.persisted? ? "Edit Template" : "New Template"
          end

          form_with(
            model: @template,
            url: @template.persisted? ? helpers.admin_template_path(@template) : helpers.admin_templates_path,
            method: @template.persisted? ? :patch : :post
          ) do |f|
            div(class: "form-control mb-4") do
              label(class: "label") do
                span(class: "label-text font-semibold") { "Template Name" }
              end
              input(
                type: "text",
                name: "feedback_template[name]",
                value: @template.name,
                class: "input input-bordered w-full",
                required: true,
                placeholder: "e.g., CSR Feedback"
              )
            end

            div(class: "form-control mb-4") do
              label(class: "label") do
                span(class: "label-text font-semibold") { "Field Schema (JSON)" }
              end
              div(class: "text-sm text-base-content/60 mb-2") do
                p { "Define fields as a JSON array. Each field should have:" }
                ul(class: "list-disc list-inside ml-2") do
                  li { "name: field identifier (snake_case)" }
                  li { "label: display label" }
                  li { "type: string, select, or richtext" }
                  li { "required: true/false" }
                  li { "options: array of choices (for select type)" }
                  li { "has_other: true to add 'Other' option with text input" }
                end
              end
              textarea(
                name: "feedback_template[field_schema]",
                class: "textarea textarea-bordered w-full font-mono text-sm",
                rows: 15,
                required: true,
                placeholder: "[\n  {\n    \"name\": \"field_name\",\n    \"label\": \"Field Label\",\n    \"type\": \"string\",\n    \"required\": true\n  }\n]"
              ) { format_json(@template.field_schema) }
            end

            div(class: "form-control mt-6 flex flex-row gap-4") do
              button(type: "submit", class: "btn btn-primary") do
                plain @template.persisted? ? "Update Template" : "Create Template"
              end
              a(href: helpers.admin_templates_path, class: "btn btn-ghost") { "Cancel" }
            end
          end
        end
      end
    end

    private

    def format_json(schema)
      return "" if schema.blank?
      JSON.pretty_generate(schema)
    rescue
      schema.to_s
    end
  end
end
