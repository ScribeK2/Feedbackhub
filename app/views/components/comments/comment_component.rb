# frozen_string_literal: true

module Comments
  class CommentComponent < ApplicationComponent
    def initialize(comment:)
      @comment = comment
    end

    def view_template
      div(id: "comment_#{@comment.id}", class: "rounded-lg bg-base-200 p-3") do
        div(class: "flex items-center justify-between gap-2") do
          span(class: "text-sm font-medium") { @comment.author.name }
          span(class: "text-xs text-base-content/50") do
            plain time_ago_in_words(@comment.created_at) + " ago"
          end
        end
        p(class: "text-sm whitespace-pre-line mt-1") { @comment.body }
      end
    end
  end
end
