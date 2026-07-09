# frozen_string_literal: true

module Comments
  class EditFormComponent < ApplicationComponent
    include Phlex::Rails::Helpers::FormWith

    def initialize(comment:)
      @comment = comment
    end

    def view_template
      div(id: "comment_#{@comment.id}", class: "rounded-lg bg-base-200 p-3") do
        form_with(url: comment_path(@comment), method: :patch) do |f|
          if @comment.errors.any?
            p(class: "text-error text-sm mb-2") do
              plain @comment.errors.full_messages.to_sentence
            end
          end
          textarea(
            name: "comment[body]",
            rows: 2,
            class: "textarea textarea-bordered w-full text-sm"
          ) { @comment.body }
          div(class: "flex gap-2 mt-2") do
            Button(:primary, :sm, type: :submit) { "Save" }
            a(href: comment_path(@comment), class: "btn btn-ghost btn-sm",
              data: { turbo_stream: true }) { "Cancel" }
          end
        end
      end
    end
  end
end
