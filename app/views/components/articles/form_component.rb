# frozen_string_literal: true

module Articles
  class FormComponent < ApplicationComponent
    def initialize(article:)
      @article = article
    end

    def view_template
      div(class: "max-w-3xl mx-auto") do
        h1(class: "text-3xl font-bold mb-6") do
          plain @article.new_record? ? "New Article" : "Edit Article"
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
        action: @article.new_record? ? articles_path : article_path(@article),
        method: "post",
        class: "space-y-4"
      ) do
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        unless @article.new_record?
          input(type: "hidden", name: "_method", value: "patch")
        end

        render_errors

        div(class: "form-control") do
          label(class: "label") do
            span(class: "label-text") { "Title" }
          end
          input(
            type: "text",
            name: "article[title]",
            value: @article.title,
            class: "input input-bordered w-full",
            required: true,
            placeholder: "Article title"
          )
        end

        div(class: "form-control", data: { controller: "tag-input" }) do
          label(class: "label") do
            span(class: "label-text") { "Tags" }
          end
          div(class: "relative") do
            input(type: "hidden", name: "tag_names", value: @article.tags.pluck(:name).join(", "),
                  data: { tag_input_target: "hidden" })
            div(id: "tag-badges", class: "flex flex-wrap gap-1 mb-2",
                data: { tag_input_target: "badges" }) do
              @article.tags.each do |tag|
                render_tag_badge(tag.name)
              end
            end
            input(
              type: "text",
              class: "input input-bordered w-full",
              placeholder: "Type a tag and press Enter or comma",
              data: {
                tag_input_target: "input",
                action: "keydown->tag-input#handleKeydown input->tag-input#search"
              }
            )
            div(
              class: "absolute z-10 w-full mt-1 bg-base-100 shadow-lg rounded-lg hidden",
              data: { tag_input_target: "suggestions" }
            )
          end
        end

        div(class: "form-control") do
          label(class: "label") do
            span(class: "label-text") { "Content" }
          end
          div(class: "min-h-[200px]") do
            raw view_context.rich_text_area_tag("article[body]", @article.body, class: "lexxy-content")
          end
        end

        div(class: "form-control mt-6 flex flex-row gap-2") do
          Button :primary, type: "submit" do
            @article.new_record? ? "Create Article" : "Update Article"
          end
          a(href: articles_path, class: "btn btn-ghost") { "Cancel" }
        end
      end
    end

    def render_errors
      return unless @article.errors.any?

      div(class: "alert alert-error") do
        ul do
          @article.errors.full_messages.each do |msg|
            li { msg }
          end
        end
      end
    end

    def render_tag_badge(name)
      span(
        class: "badge badge-outline gap-1",
        data: { tag_input_target: "badge", tag_name: name }
      ) do
        plain name
        button(
          type: "button",
          class: "text-xs opacity-60 hover:opacity-100",
          data: { action: "click->tag-input#removeTag" }
        ) { "x" }
      end
    end
  end
end
