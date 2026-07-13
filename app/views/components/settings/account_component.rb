# frozen_string_literal: true

module Settings
  class AccountComponent < ApplicationComponent
    def initialize(user:, password_error: nil)
      @user = user
      @password_error = password_error
    end

    def view_template
      div(class: "max-w-2xl mx-auto") do
        render Settings::TabsComponent.new(active: :account)
        h1(class: "text-2xl font-bold mb-6") { "Account" }
        profile_card
        password_card
      end
    end

    private

    def profile_card
      Card :base_100, class: "shadow mb-6" do |card|
        card.body do
          h2(class: "text-lg font-semibold mb-4") { "Profile" }
          form(action: settings_profile_path, method: "post", class: "space-y-4") do
            hidden_fields
            error_alert(%i[name email])
            field("Name", "user[name]", type: "text", value: @user.name)
            field("Email", "user[email]", type: "email", value: @user.email)
            submit_row("Save profile")
          end
        end
      end
    end

    def password_card
      Card :base_100, class: "shadow" do |card|
        card.body do
          h2(class: "text-lg font-semibold mb-4") { "Password" }
          form(action: settings_password_path, method: "post", class: "space-y-4") do
            hidden_fields
            error_alert(%i[password password_confirmation], extra: @password_error)
            field("Current password", "user[current_password]", type: "password")
            field("New password", "user[password]", type: "password")
            field("Confirm new password", "user[password_confirmation]", type: "password")
            submit_row("Change password")
          end
        end
      end
    end

    def hidden_fields
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
      input(type: "hidden", name: "_method", value: "patch")
    end

    def field(label_text, name, type:, value: nil)
      div(class: "form-control") do
        label(class: "label") { span(class: "label-text") { label_text } }
        input(type: type, name: name, value: value,
              class: "input input-bordered w-full", required: true)
      end
    end

    def submit_row(label)
      div(class: "form-control mt-2") do
        Button :primary, type: "submit" do
          label
        end
      end
    end

    def error_alert(attributes, extra: nil)
      messages = @user.errors.select { |e| attributes.include?(e.attribute) }.map(&:full_message)
      messages.unshift(extra) if extra.present?
      return if messages.empty?

      div(class: "alert alert-error") do
        ul do
          messages.each { |msg| li { msg } }
        end
      end
    end
  end
end
