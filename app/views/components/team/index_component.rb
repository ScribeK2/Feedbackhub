# frozen_string_literal: true

module Team
  class IndexComponent < ApplicationComponent
    def initialize(memberships:, csr_options:)
      @memberships = memberships
      @csr_options = csr_options
    end

    def view_template
      div(class: "space-y-6", data: { controller: "toggle" }) do
        render_header
        render_team_list
        render_add_form
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-center") do
        h1(class: "page-title") { "My Team" }
        button(
          type: "button",
          class: "btn btn-primary btn-sm",
          data: { action: "toggle#toggle" }
        ) { "Add team member" }
      end
    end

    def render_team_list
      Card class: "surface" do |card|
        card.body do
          h2(class: "card-title text-lg font-bold mb-4") { "Team list" }
          if @memberships.empty?
            p(class: "text-base-content/60") do
              plain "No CSRs yet. You currently see all feedback. Add a CSR to scope your view."
            end
          else
            ul(class: "space-y-2") do
              @memberships.each { |m| render_member_row(m) }
            end
          end
        end
      end
    end

    def render_member_row(membership)
      li(class: "flex items-center justify-between p-2 rounded bg-base-200") do
        span(class: "font-medium") { membership.csr_name }
        form(action: team_membership_path(membership), method: "post", class: "inline") do
          input(type: "hidden", name: "_method", value: "delete")
          input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
          button(type: "submit", class: "btn btn-ghost btn-xs text-error") { "Remove" }
        end
      end
    end

    def render_add_form
      div(class: "hidden", data: { toggle_target: "panel" }) do
        form(action: team_memberships_path, method: "post", class: "flex gap-2 items-end") do
          input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
          div(class: "form-control flex-1") do
            label(class: "label") { span(class: "label-text text-sm") { "CSR" } }
            select(name: "csr_name", class: "select select-bordered select-sm w-full") do
              option(value: "") { "Select a CSR…" }
              @csr_options.each { |name| option(value: name) { name } }
            end
          end
          Button(:primary, :sm, type: "submit") { "Save" }
        end
      end
    end
  end
end
