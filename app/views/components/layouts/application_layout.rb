module Layouts
  class ApplicationLayout < ApplicationComponent
    include Phlex::Rails::Layout
    include Phlex::Rails::Helpers::StylesheetLinkTag
    include Phlex::Rails::Helpers::JavaScriptImportmapTags
    include Phlex::Rails::Helpers::CSPMetaTag
    include Phlex::Rails::Helpers::CSRFMetaTags

    def initialize(title: "FeedbackHub")
      @title = title
    end

    def view_template
      doctype
      html(data: { theme: "corporate" }) do
        head do
          title { @title }
          meta(name: "viewport", content: "width=device-width, initial-scale=1")
          meta(name: "view-transition", content: "same-origin")
          csp_meta_tag
          csrf_meta_tags
          stylesheet_link_tag :app, "data-turbo-track": "reload"
          javascript_importmap_tags
        end

        body(class: "min-h-screen bg-base-200") do
          render_header
          main(class: "container mx-auto px-4 py-8 pt-24") do
            render Shared::FlashComponent.new(flash: helpers.flash)
            yield
          end
        end
      end
    end

    private

    def render_header
      header(class: "navbar-glass fixed top-0 left-0 right-0 z-50") do
        div(class: "container mx-auto px-4") do
          div(class: "navbar min-h-16") do
            div(class: "flex-1") do
              a(href: helpers.root_path, class: "flex items-center gap-2 text-xl font-bold hover:opacity-80 transition-opacity") do
                render_logo
                span { "FeedbackHub" }
              end
            end
            div(class: "flex-none") do
              nav(class: "flex items-center gap-1") do
                a(href: helpers.hub_path, class: "nav-link") do
                  render_icon("M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6")
                  span { "Hub" }
                end
                a(href: helpers.new_feedback_path, class: "nav-link") do
                  render_icon("M12 4v16m8-8H4")
                  span { "Submit" }
                end
                a(href: helpers.admin_templates_path, class: "nav-link") do
                  render_icon("M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z")
                  span { "Templates" }
                end
                div(class: "divider divider-horizontal mx-2 h-6 self-center")
                render Shared::ThemeToggleComponent.new
              end
            end
          end
        end
      end
    end

    def render_logo
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        class: "h-8 w-8 text-primary",
        fill: "none",
        viewBox: "0 0 24 24",
        stroke: "currentColor",
        stroke_width: "1.5"
      ) do |s|
        s.path(
          stroke_linecap: "round",
          stroke_linejoin: "round",
          d: "M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"
        )
      end
    end

    def render_icon(path)
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        class: "h-4 w-4",
        fill: "none",
        viewBox: "0 0 24 24",
        stroke: "currentColor",
        stroke_width: "2"
      ) do |s|
        s.path(
          stroke_linecap: "round",
          stroke_linejoin: "round",
          d: path
        )
      end
    end
  end
end
