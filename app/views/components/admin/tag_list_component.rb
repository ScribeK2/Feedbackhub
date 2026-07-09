# frozen_string_literal: true

module Admin
  class TagListComponent < ApplicationComponent
    def initialize(tags:)
      @tags = tags
    end

    def view_template
      div(class: "space-y-6") do
        h1(class: "page-title") { "Tags" }
        render_table
      end
    end

    private

    def render_table
      div(class: "overflow-x-auto") do
        table(class: "table table-zebra w-full") do
          thead do
            tr do
              th { "Name" }
              th { "Articles" }
              th { "Actions" }
            end
          end
          tbody do
            @tags.each { |tag| render_tag_row(tag) }
          end
        end
      end
    end

    def render_tag_row(tag)
      tr do
        td(class: "font-medium") { tag.name }
        td { tag.articles.count.to_s }
        td(class: "flex gap-1") do
          a(href: edit_admin_tag_path(tag), class: "btn btn-ghost btn-xs") { "Edit" }
          form(action: admin_tag_path(tag), method: "post", class: "inline") do
            input(type: "hidden", name: "_method", value: "delete")
            input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
            button(
              type: "submit",
              class: "btn btn-ghost btn-xs text-error",
              data: { turbo_confirm: "Delete #{tag.name}? It is removed from every article carrying it." }
            ) { "Delete" }
          end
        end
      end
    end
  end
end
