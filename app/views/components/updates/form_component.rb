# frozen_string_literal: true

module Updates
  class FormComponent < ApplicationComponent
    def view_template
      Modal :tap_outside_to_close, id: "new-update-modal" do |modal|
        modal.body class: "max-w-2xl bg-base-100/95 backdrop-blur-md" do
          h3(class: "font-bold text-xl mb-4") { "Add New Update" }
          render_form
          modal.action do
            modal.close_button { "Cancel" }
          end
        end
      end
    end

    private

    def render_form
      form(action: updates_path, method: "post", class: "space-y-4") do
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)

        div(class: "form-control") do
          label(class: "label") do
            span(class: "label-text") { "Date" }
          end
          input(
            type: "date",
            name: "update[date]",
            value: Date.today.to_s,
            class: "input input-bordered w-full",
            required: true
          )
        end

        div(class: "form-control") do
          label(class: "label") do
            span(class: "label-text") { "Content" }
          end
          div(class: "min-h-[200px]") do
            raw view_context.rich_text_area_tag("update[body]", nil, class: "lexxy-content")
          end
        end

        div(class: "form-control") do
          label(class: "label cursor-pointer justify-start gap-3") do
            input(type: "checkbox", name: "update[pinned]", value: "1", class: "checkbox checkbox-primary")
            span(class: "label-text") { "Pin this update" }
          end
        end

        div(class: "form-control mt-4") do
          Button :primary, type: "submit" do
            "Post Update"
          end
        end
      end
    end
  end
end
