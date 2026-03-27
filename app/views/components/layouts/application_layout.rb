# frozen_string_literal: true

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
          render_header if current_user
          main(class: "container mx-auto px-4 py-8 pt-24") do
            render Shared::FlashComponent.new(flash: flash)
            yield
          end
        end
      end
    end

    private

    def render_header
      header(class: "navbar-glass fixed top-0 left-0 right-0 z-50") do
        div(class: "container mx-auto px-4") do
          nav(class: "flex items-center min-h-16 py-2 gap-4") do
            div(class: "flex-1") do
              render_search
            end
            div(class: "flex-none") do
              render_logo_launcher
            end
            div(class: "flex-1 flex items-center justify-end gap-2") do
              render Shared::ThemeToggleComponent.new
              render_user_menu
            end
          end
        end
      end
    end

    def render_search
      div(class: "relative", data: { controller: "search" }) do
        input(
          type: "search",
          placeholder: "Search feedbacks & articles...",
          class: "input input-bordered input-sm w-48 lg:w-64",
          data: { search_target: "input", action: "input->search#submit" }
        )
        div(
          class: "absolute top-full left-0 w-80 mt-1 bg-base-100 shadow-xl rounded-lg overflow-hidden z-50 hidden",
          data: { search_target: "results" }
        )
      end
    end

    def render_logo_launcher
      div(class: "flex items-center gap-1") do
        a(href: root_path, class: "flex items-center gap-2 text-xl font-bold hover:opacity-80 transition-opacity") do
          render_logo
          span(class: "hidden sm:inline") { "FeedbackHub" }
        end

        Dropdown do |dropdown|
          dropdown.button :ghost, :sm, class: "px-1" do
            render_chevron_down
          end
          dropdown.menu :base_100, class: "w-56 mt-2 shadow-lg" do |menu|
            menu.item do
              a(href: feedback_index_path, class: "flex items-center gap-2") do
                render_icon("M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2")
                plain "Feedbacks"
              end
            end
            menu.item do
              a(href: tools_path, class: "flex items-center gap-2") do
                render_icon("M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z")
                plain "Tools"
              end
            end
            menu.item do
              a(href: articles_path, class: "flex items-center gap-2") do
                render_icon("M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253")
                plain "Knowledge Base"
              end
            end
            menu.item do
              a(href: updates_path, class: "flex items-center gap-2") do
                render_icon("M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z")
                plain "Updates"
              end
            end
            if current_user&.admin?
              div(class: "divider my-1")
              menu.item do
                a(href: admin_templates_path, class: "flex items-center gap-2") do
                  render_icon("M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z")
                  plain "Templates"
                end
              end
              menu.item do
                a(href: admin_users_path, class: "flex items-center gap-2") do
                  render_icon("M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z")
                  plain "Manage Users"
                end
              end
            end
          end
        end
      end
    end

    def render_user_menu
      Dropdown :end do |dropdown|
        dropdown.button :ghost, :sm, class: "flex items-center gap-2 text-sm font-medium opacity-70 hover:opacity-100" do
          render_icon("M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z")
          span(class: "hidden lg:inline") { current_user.name }
        end
        dropdown.menu :base_100, class: "w-48 mt-2 shadow-lg" do |menu|
          menu.item do
            span(class: "text-sm opacity-60") { current_user.email }
          end
          if current_user.admin?
            menu.item do
              span(class: "badge badge-sm badge-primary") { "Admin" }
            end
          end
          menu.item do
            form(action: logout_path, method: "post") do
              input(type: "hidden", name: "_method", value: "delete")
              input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
              button(type: "submit", class: "w-full text-left text-error") { "Sign Out" }
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

    def render_chevron_down
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        class: "h-4 w-4",
        fill: "none",
        viewBox: "0 0 24 24",
        stroke: "currentColor",
        stroke_width: "2"
      ) do |s|
        s.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M19 9l-7 7-7-7")
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
