# frozen_string_literal: true

module Admin
  class TemplateFormComponent < ApplicationComponent
    include Phlex::Rails::Helpers::FormWith

    def initialize(template:)
      @template = template
    end

    def view_template
      Card :base_100, class: "shadow-xl max-w-4xl mx-auto" do |card|
        card.body do
          card.title class: "text-2xl mb-6" do
            plain @template.persisted? ? "Edit Template" : "New Template"
          end

          form_with(
            model: @template,
            url: @template.persisted? ? admin_template_path(@template) : admin_templates_path,
            method: @template.persisted? ? :patch : :post
          ) do |f|
            render_name_field
            render_schema_field
            render_actions
          end
        end
      end
    end

    private

    def render_name_field
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
    end

    def render_schema_field
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
    end

    def render_actions
      div(class: "form-control mt-6 flex flex-row gap-4") do
        Button(:primary, type: :submit) do
          plain @template.persisted? ? "Update Template" : "Create Template"
        end
        Button(:ghost, as: :a, href: admin_templates_path) { "Cancel" }
      end
    end

    def format_json(schema)
      return "" if schema.blank?
      JSON.pretty_generate(schema)
    rescue
      schema.to_s
    end
  end
end
