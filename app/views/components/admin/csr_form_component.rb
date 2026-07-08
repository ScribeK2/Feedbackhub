# frozen_string_literal: true

module Admin
  class CsrFormComponent < ApplicationComponent
    def initialize(csr:, users:, merge_targets:)
      @csr = csr
      @users = users
      @merge_targets = merge_targets
    end

    def view_template
      div(class: "max-w-lg mx-auto space-y-6") do
        h1(class: "page-title") do
          plain @csr.new_record? ? "New CSR" : "Edit CSR"
        end

        Card class: "surface" do |card|
          card.body do
            render_form
          end
        end

        render_merge_card if @csr.persisted? && @merge_targets.any?
      end
    end

    private

    def render_form
      form(
        action: @csr.new_record? ? admin_csrs_path : admin_csr_path(@csr),
        method: "post",
        class: "space-y-4"
      ) do
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        unless @csr.new_record?
          input(type: "hidden", name: "_method", value: "patch")
        end

        render_errors

        div(class: "form-control") do
          label(class: "label") { span(class: "label-text") { "Name" } }
          input(type: "text", name: "csr[name]", value: @csr.name,
                class: "input input-bordered w-full", required: true)
          unless @csr.new_record?
            span(class: "label-text-alt text-base-content/60 mt-1") do
              plain "Renaming rewrites this CSR's name on all existing feedback and team memberships."
            end
          end
        end

        div(class: "form-control") do
          label(class: "label cursor-pointer justify-start gap-3") do
            input(type: "hidden", name: "csr[active]", value: "0")
            input(type: "checkbox", name: "csr[active]", value: "1",
                  class: "checkbox checkbox-primary", checked: @csr.active)
            span(class: "label-text") { "Active (offered on the feedback and team forms)" }
          end
        end

        div(class: "form-control") do
          label(class: "label") { span(class: "label-text") { "Linked user (for future self-view)" } }
          select(name: "csr[user_id]", class: "select select-bordered w-full") do
            option(value: "") { "— none —" }
            @users.each do |user|
              if @csr.user_id == user.id
                option(value: user.id, selected: true) { user.name }
              else
                option(value: user.id) { user.name }
              end
            end
          end
        end

        div(class: "form-control mt-6 flex flex-row gap-2") do
          Button :primary, type: "submit" do
            @csr.new_record? ? "Create CSR" : "Update CSR"
          end
          a(href: admin_csrs_path, class: "btn btn-ghost") { "Cancel" }
        end
      end
    end

    def render_merge_card
      Card class: "surface" do |card|
        card.body do
          h2(class: "card-title text-lg font-bold") { "Merge" }
          p(class: "text-sm text-base-content/60 mb-2") do
            plain "Moves all of #{@csr.name}'s feedback and team memberships to another CSR, then deletes #{@csr.name}. This cannot be undone."
          end
          form(action: merge_admin_csr_path(@csr), method: "post", class: "flex gap-2 items-end") do
            input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
            div(class: "form-control flex-1") do
              label(class: "label") { span(class: "label-text text-sm") { "Merge into" } }
              select(name: "target_id", class: "select select-bordered select-sm w-full", required: true) do
                option(value: "") { "Select a CSR…" }
                @merge_targets.each { |target| option(value: target.id) { target.name } }
              end
            end
            button(
              type: "submit",
              class: "btn btn-error btn-sm",
              data: { turbo_confirm: "Merge #{@csr.name}? All references move and #{@csr.name} is deleted." }
            ) { "Merge" }
          end
        end
      end
    end

    def render_errors
      return unless @csr.errors.any?

      div(class: "alert alert-error") do
        ul do
          @csr.errors.full_messages.each { |msg| li { msg } }
        end
      end
    end
  end
end
