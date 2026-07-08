# frozen_string_literal: true

module Admin
  class CsrListComponent < ApplicationComponent
    def initialize(csrs:)
      @csrs = csrs
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
        h1(class: "page-title") { "CSRs" }
        Button(:primary, as: :a, href: new_admin_csr_path) { "New CSR" }
      end
    end

    def render_table
      div(class: "overflow-x-auto") do
        table(class: "table table-zebra w-full") do
          thead do
            tr do
              th { "Name" }
              th { "Status" }
              th { "Linked User" }
              th { "Feedback" }
              th { "Team refs" }
              th { "Actions" }
            end
          end
          tbody do
            @csrs.each { |csr| render_csr_row(csr) }
          end
        end
      end
    end

    def render_csr_row(csr)
      tr do
        td(class: "font-medium") { csr.name }
        td { render_status_badge(csr) }
        td(class: "text-sm text-base-content/60") { csr.user&.name || "—" }
        td { csr.submission_count.to_s }
        td { csr.membership_count.to_s }
        td(class: "flex gap-1") do
          a(href: edit_admin_csr_path(csr), class: "btn btn-ghost btn-xs") { "Edit" }
          unless csr.referenced?
            form(action: admin_csr_path(csr), method: "post", class: "inline") do
              input(type: "hidden", name: "_method", value: "delete")
              input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
              button(
                type: "submit",
                class: "btn btn-ghost btn-xs text-error",
                data: { turbo_confirm: "Delete #{csr.name}?" }
              ) { "Delete" }
            end
          end
        end
      end
    end

    def render_status_badge(csr)
      if csr.active
        Badge(:primary, :sm) { "Active" }
      else
        Badge(:ghost, :sm) { "Inactive" }
      end
    end
  end
end
