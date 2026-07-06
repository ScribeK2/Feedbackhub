# frozen_string_literal: true

module Comments
  class FormComponent < ApplicationComponent
    include Phlex::Rails::Helpers::FormWith

    def initialize(submission:, comment: nil)
      @submission = submission
      @comment = comment
    end

    def view_template
      form_with(
        url: feedback_comments_path(@submission),
        id: "comment_form_#{@submission.id}"
      ) do |f|
        if @comment&.errors&.any?
          p(class: "text-error text-sm mb-2") do
            plain @comment.errors.full_messages.to_sentence
          end
        end
        div(class: "flex items-end gap-2") do
          textarea(
            name: "comment[body]",
            rows: 2,
            placeholder: "Add a comment...",
            class: "textarea textarea-bordered w-full text-sm"
          ) { @comment&.body }
          Button(:primary, :sm, type: :submit) { "Comment" }
        end
      end
    end
  end
end
