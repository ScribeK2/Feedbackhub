# frozen_string_literal: true

module Admin
  class ToolListComponent < ApplicationComponent
    def initialize(tools:)
      @tools = tools
    end

    def view_template
      div(class: "space-y-6") do
        render_header
        render_table
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-center") do
        h1(class: "page-title") { "Tools" }
        Button(:primary, as: :a, href: new_admin_tool_path) { "New Tool" }
      end
    end

    def render_table
      div(class: "overflow-x-auto") do
        table(class: "table table-zebra w-full") do
          thead do
            tr do
              th { "Name" }
              th { "URL" }
              th { "Position" }
              th { "Status" }
              th { "Actions" }
            end
          end
          tbody do
            @tools.each { |tool| render_tool_row(tool) }
          end
        end
      end
    end

    def render_tool_row(tool)
      tr do
        td(class: "font-medium") { tool.name }
        td(class: "text-sm text-base-content/60") { tool.url }
        td { tool.position.to_s }
        td { render_status_badge(tool) }
        td(class: "flex gap-1") do
          a(href: edit_admin_tool_path(tool), class: "btn btn-ghost btn-xs") { "Edit" }
          form(action: admin_tool_path(tool), method: "post", class: "inline") do
            input(type: "hidden", name: "_method", value: "delete")
            input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
            button(
              type: "submit",
              class: "btn btn-ghost btn-xs text-error",
              data: { turbo_confirm: "Delete #{tool.name}?" }
            ) { "Delete" }
          end
        end
      end
    end

    def render_status_badge(tool)
      if tool.active
        Badge(:primary, :sm) { "Active" }
      else
        Badge(:ghost, :sm) { "Inactive" }
      end
    end
  end
end
