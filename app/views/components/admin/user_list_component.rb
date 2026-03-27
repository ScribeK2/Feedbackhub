# frozen_string_literal: true

module Admin
  class UserListComponent < ApplicationComponent
    def initialize(users:)
      @users = users
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
        h1(class: "text-3xl font-bold") { "Manage Users" }
        Button(:primary, as: :a, href: new_admin_user_path) { "New User" }
      end
    end

    def render_table
      div(class: "overflow-x-auto") do
        table(class: "table table-zebra w-full") do
          thead do
            tr do
              th { "Name" }
              th { "Email" }
              th { "Role" }
              th { "Created" }
              th { "Actions" }
            end
          end
          tbody do
            @users.each { |user| render_user_row(user) }
          end
        end
      end
    end

    def render_user_row(user)
      tr do
        td(class: "font-medium") { user.name }
        td { user.email }
        td do
          if user.admin?
            Badge(:primary, :sm) { "Admin" }
          else
            Badge(:ghost, :sm) { "User" }
          end
        end
        td(class: "text-sm text-base-content/60") { time_ago_in_words(user.created_at) + " ago" }
        td(class: "flex gap-1") do
          a(href: edit_admin_user_path(user), class: "btn btn-ghost btn-xs") { "Edit" }
          unless user == current_user
            form(action: admin_user_path(user), method: "post", class: "inline") do
              input(type: "hidden", name: "_method", value: "delete")
              input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
              button(
                type: "submit",
                class: "btn btn-ghost btn-xs text-error",
                data: { turbo_confirm: "Delete #{user.name}?" }
              ) { "Delete" }
            end
          end
        end
      end
    end
  end
end
