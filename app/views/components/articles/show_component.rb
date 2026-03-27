# frozen_string_literal: true

module Articles
  class ShowComponent < ApplicationComponent
    def initialize(article:)
      @article = article
    end

    def view_template
      div(class: "space-y-6") do
        render_header
        render_body
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-start") do
        div do
          a(href: articles_path, class: "link link-hover text-sm text-base-content/60 mb-2 inline-block") do
            plain "Back to Knowledge Base"
          end
          h1(class: "text-3xl font-bold") { @article.title }
          p(class: "text-base-content/60 mt-1") do
            plain "by #{@article.author.name} — #{time_ago_in_words(@article.created_at)} ago"
          end
          if @article.tags.any?
            div(class: "flex flex-wrap gap-1 mt-3") do
              @article.tags.each do |tag|
                a(href: articles_path(tag: tag.name)) do
                  Badge(:outline, :sm) { tag.name }
                end
              end
            end
          end
        end
        if current_user&.admin?
          form(action: article_path(@article), method: "post") do
            input(type: "hidden", name: "_method", value: "delete")
            input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
            Button :error, :outline, :sm, type: "submit",
              data: { turbo_confirm: "Delete this article?" } do
              "Delete"
            end
          end
        end
      end
    end

    def render_body
      Card class: "glass-card" do |card|
        card.body do
          if @article.body.present?
            div(class: "prose max-w-none") do
              raw @article.body.to_s
            end
          else
            p(class: "text-base-content/50 italic") { "No content." }
          end
        end
      end
    end
  end
end
