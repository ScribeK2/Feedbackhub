# frozen_string_literal: true

module Sessions
  class LoginComponent < ApplicationComponent
    def view_template
      div(class: "flex items-center justify-center min-h-[60vh]") do
        Card class: "glass-card w-full max-w-md" do |card|
          card.body do
            h2(class: "card-title text-2xl font-bold mb-6 justify-center") { "Sign In" }

            form(action: login_path, method: "post") do
              input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)

              div(class: "form-control mb-4") do
                label(class: "label") do
                  span(class: "label-text") { "Email" }
                end
                input(
                  type: "email",
                  name: "email",
                  class: "input input-bordered w-full",
                  placeholder: "you@example.com",
                  required: true,
                  autofocus: true
                )
              end

              div(class: "form-control mb-6") do
                label(class: "label") do
                  span(class: "label-text") { "Password" }
                end
                input(
                  type: "password",
                  name: "password",
                  class: "input input-bordered w-full",
                  placeholder: "Enter your password",
                  required: true
                )
              end

              div(class: "form-control") do
                Button :primary, type: "submit", class: "w-full" do
                  "Sign In"
                end
              end
            end
          end
        end
      end
    end
  end
end
