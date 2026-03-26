# frozen_string_literal: true

module Feedback
  class FormComponent < ApplicationComponent
    include Phlex::Rails::Helpers::FormWith
    include Phlex::Rails::Helpers::TurboFrameTag
    include Phlex::Rails::Helpers::HiddenFieldTag

    def initialize(templates:, selected_template: nil, submission: nil)
      @templates = templates
      @selected_template = selected_template
      @submission = submission || FeedbackSubmission.new
    end

    def view_template
      Card :base_100, class: "shadow-xl max-w-4xl mx-auto" do |card|
        card.body do
          card.title class: "text-2xl mb-6" do
            plain "Submit Feedback"
          end

          render_template_selector
          render_form_frame
        end
      end
    end

    private

    def render_template_selector
      form_with(
        url: form_feedback_index_path,
        method: :get,
        data: { turbo_frame: "feedback_form", controller: "form" }
      ) do |f|
        div(class: "form-control mb-6") do
          label(class: "label") do
            span(class: "label-text font-semibold") { "Select Template" }
          end
          select(
            name: "template_id",
            class: "select select-bordered w-full",
            data: { action: "change->form#switchTemplate", form_target: "templateSelect" }
          ) do
            option(value: "") { "Choose a template..." }
            @templates.each do |template|
              if @selected_template&.id == template.id
                option(value: template.id, selected: true) { template.name }
              else
                option(value: template.id) { template.name }
              end
            end
          end
        end
      end
    end

    def render_form_frame
      turbo_frame_tag "feedback_form" do
        if @selected_template
          render_dynamic_form
        else
          div(class: "text-center text-base-content/60 py-8") do
            p { "Select a template to begin" }
          end
        end
      end
    end

    def render_dynamic_form
      form_with(
        model: @submission,
        url: feedback_index_path,
        data: { controller: "other-field" }
      ) do |f|
        hidden_field_tag :feedback_template_id, @selected_template.id

        @selected_template.field_schema.each do |field|
          render_field(field.with_indifferent_access)
        end

        div(class: "form-control mt-6") do
          Button(:primary, type: :submit) { "Submit Feedback" }
        end
      end
    end

    def render_field(field)
      div(class: "form-control mb-4", data: other_field_wrapper(field)) do
        label(class: "label") do
          span(class: "label-text font-semibold") do
            plain field[:label]
            span(class: "text-error") { " *" } if field[:required]
          end
        end

        case field[:type]
        when "string"
          input(
            type: "text",
            name: "data[#{field[:name]}]",
            class: "input input-bordered w-full",
            required: field[:required]
          )
        when "select"
          render_select_field(field)
        when "richtext"
          render_richtext_field(field)
        end
      end
    end

    def render_select_field(field)
      select(
        name: "data[#{field[:name]}]",
        class: "select select-bordered w-full",
        required: field[:required],
        data: field[:has_other] ? { other_field_target: "select", action: "change->other-field#toggle" } : {}
      ) do
        option(value: "") { "Select..." }
        field[:options]&.each do |opt|
          option(value: opt) { opt }
        end
      end

      if field[:has_other]
        div(
          class: "mt-2 hidden",
          data: { other_field_target: "input" }
        ) do
          input(
            type: "text",
            name: "data[#{field[:name]}_other]",
            placeholder: "Please specify...",
            class: "input input-bordered w-full"
          )
        end
      end
    end

    def render_richtext_field(field)
      div(class: "min-h-[200px]") do
        raw view_context.rich_text_area_tag(
          "feedback_submission[#{field[:name]}]",
          @submission.send(field[:name]),
          class: "lexxy-content"
        )
      end
    end

    def other_field_wrapper(field)
      return {} unless field[:has_other]
      { other_field_target: "wrapper" }
    end
  end
end
