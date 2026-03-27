# frozen_string_literal: true

module Admin
  class UserFormComponent < ApplicationComponent
    def initialize(user:)
      @user = user
    end

    def view_template
      div(class: "max-w-lg mx-auto") do
        h1(class: "text-3xl font-bold mb-6") do
          plain @user.new_record? ? "New User" : "Edit User"
        end

        Card class: "glass-card" do |card|
          card.body do
            render_form
          end
        end
      end
    end

    private

    def render_form
      form(
        action: @user.new_record? ? admin_users_path : admin_user_path(@user),
        method: "post",
        class: "space-y-4"
      ) do
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        unless @user.new_record?
          input(type: "hidden", name: "_method", value: "patch")
        end

        render_errors

        div(class: "form-control") do
          label(class: "label") { span(class: "label-text") { "Name" } }
          input(type: "text", name: "user[name]", value: @user.name,
                class: "input input-bordered w-full", required: true)
        end

        div(class: "form-control") do
          label(class: "label") { span(class: "label-text") { "Email" } }
          input(type: "email", name: "user[email]", value: @user.email,
                class: "input input-bordered w-full", required: true)
        end

        div(class: "form-control") do
          label(class: "label") { span(class: "label-text") { "Role" } }
          select(name: "user[role]", class: "select select-bordered w-full") do
            %w[user admin].each do |role|
              if @user.role == role
                option(value: role, selected: true) { role.capitalize }
              else
                option(value: role) { role.capitalize }
              end
            end
          end
        end

        div(class: "form-control") do
          label(class: "label") do
            span(class: "label-text") do
              plain @user.new_record? ? "Password" : "Password (leave blank to keep current)"
            end
          end
          input(type: "password", name: "user[password]",
                class: "input input-bordered w-full",
                required: @user.new_record?)
        end

        div(class: "form-control") do
          label(class: "label") { span(class: "label-text") { "Password Confirmation" } }
          input(type: "password", name: "user[password_confirmation]",
                class: "input input-bordered w-full",
                required: @user.new_record?)
        end

        div(class: "form-control mt-6 flex flex-row gap-2") do
          Button :primary, type: "submit" do
            @user.new_record? ? "Create User" : "Update User"
          end
          a(href: admin_users_path, class: "btn btn-ghost") { "Cancel" }
        end
      end
    end

    def render_errors
      return unless @user.errors.any?

      div(class: "alert alert-error") do
        ul do
          @user.errors.full_messages.each { |msg| li { msg } }
        end
      end
    end
  end
end
