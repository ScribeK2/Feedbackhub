# frozen_string_literal: true

module Comments
  class CommentComponent < ApplicationComponent
    def initialize(comment:, user: nil)
      @comment = comment
      @user = user
    end

    def view_template
      div(id: "comment_#{@comment.id}", class: "rounded-lg bg-base-200 p-3") do
        div(class: "flex items-center justify-between gap-2") do
          span(class: "text-sm font-medium") { @comment.author.name }
          div(class: "flex items-center gap-1") do
            span(class: "text-xs text-base-content/50") do
              plain time_ago_in_words(@comment.created_at) + " ago"
              plain " (edited)" if @comment.edited?
            end
            render_controls
          end
        end
        p(class: "text-sm whitespace-pre-line mt-1") { @comment.body }
      end
    end

    private

    def render_controls
      return unless @user

      if @comment.author == @user
        a(href: edit_comment_path(@comment), class: "btn btn-ghost btn-xs",
          data: { turbo_stream: true }) { "Edit" }
      end
      if @comment.author == @user || @user.admin?
        form(action: comment_path(@comment), method: "post", class: "inline") do
          input(type: "hidden", name: "_method", value: "delete")
          input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
          button(
            type: "submit",
            class: "btn btn-ghost btn-xs text-error",
            data: { turbo_confirm: "Delete this comment?" }
          ) { "Delete" }
        end
      end
    end
  end
end
