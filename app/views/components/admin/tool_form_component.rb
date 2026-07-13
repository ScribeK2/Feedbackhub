# frozen_string_literal: true

module Admin
  class ToolFormComponent < ApplicationComponent
    def initialize(tool:)
      @tool = tool
    end

    def view_template
      div(class: "max-w-lg mx-auto space-y-6") do
        h1(class: "page-title") { @tool.new_record? ? "New Tool" : "Edit Tool" }

        Card class: "surface" do |card|
          card.body do
            render_form
          end
        end
      end
    end

    private

    def render_form
      form(
        action: @tool.new_record? ? admin_tools_path : admin_tool_path(@tool),
        method: "post",
        class: "space-y-4"
      ) do
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        unless @tool.new_record?
          input(type: "hidden", name: "_method", value: "patch")
        end

        render_errors

        div(class: "form-control") do
          label(class: "label") { span(class: "label-text") { "Name" } }
          input(type: "text", name: "tool[name]", value: @tool.name,
                class: "input input-bordered w-full", required: true)
        end

        div(class: "form-control") do
          label(class: "label") { span(class: "label-text") { "URL" } }
          input(type: "url", name: "tool[url]", value: @tool.url,
                class: "input input-bordered w-full", required: true,
                placeholder: "https://example.com")
        end

        div(class: "form-control") do
          label(class: "label") { span(class: "label-text") { "Description" } }
          input(type: "text", name: "tool[description]", value: @tool.description,
                class: "input input-bordered w-full")
        end

        div(class: "form-control") do
          label(class: "label") { span(class: "label-text") { "Position" } }
          input(type: "number", name: "tool[position]", value: @tool.position || 0,
                min: "0", class: "input input-bordered w-full")
          span(class: "label-text-alt text-base-content/60 mt-1") do
            plain "Lower numbers appear first on the Tools page."
          end
        end

        render_icon_picker

        div(class: "form-control") do
          label(class: "label cursor-pointer justify-start gap-3") do
            input(type: "hidden", name: "tool[active]", value: "0")
            input(type: "checkbox", name: "tool[active]", value: "1",
                  class: "checkbox checkbox-primary", checked: @tool.active)
            span(class: "label-text") { "Active (shown on the Tools page)" }
          end
        end

        div(class: "form-control mt-6 flex flex-row gap-2") do
          Button :primary, type: "submit" do
            @tool.new_record? ? "Create Tool" : "Update Tool"
          end
          a(href: admin_tools_path, class: "btn btn-ghost") { "Cancel" }
        end
      end
    end

    def render_icon_picker
      div(class: "form-control") do
        label(class: "label") { span(class: "label-text") { "Icon" } }
        div(class: "grid grid-cols-4 sm:grid-cols-6 gap-2") do
          Tool::ICONS.each do |key, path|
            label(class: "cursor-pointer") do
              input(type: "radio", name: "tool[icon_key]", value: key,
                    class: "peer sr-only", checked: @tool.icon_key == key, required: true)
              div(class: "flex flex-col items-center gap-1 rounded-lg border border-base-300 p-2 hover:border-primary/50 peer-checked:border-primary peer-checked:bg-primary/10") do
                render_icon(path)
                span(class: "text-[10px] text-base-content/60 truncate w-full text-center") { key }
              end
            end
          end
        end
      end
    end

    def render_icon(path)
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        class: "h-6 w-6 text-primary",
        fill: "none",
        viewBox: "0 0 24 24",
        stroke: "currentColor",
        stroke_width: "1.5"
      ) do |s|
        s.path(stroke_linecap: "round", stroke_linejoin: "round", d: path)
      end
    end

    def render_errors
      return unless @tool.errors.any?

      div(class: "alert alert-error") do
        ul do
          @tool.errors.full_messages.each { |msg| li { msg } }
        end
      end
    end
  end
end
