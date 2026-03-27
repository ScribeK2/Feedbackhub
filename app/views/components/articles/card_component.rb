# frozen_string_literal: true

module Articles
  class CardComponent < ApplicationComponent
    def initialize(article:)
      @article = article
    end

    def view_template
      a(href: article_path(@article), class: "block") do
        Card class: "glass-card hover:shadow-xl transition-all duration-300 cursor-pointer h-full" do |card|
          card.body do
            h2(class: "card-title text-lg") { @article.title }
            p(class: "text-sm text-base-content/60 mb-3") do
              plain "by #{@article.author.name} — #{time_ago_in_words(@article.created_at)} ago"
            end
            if @article.tags.any?
              div(class: "flex flex-wrap gap-1 mb-3") do
                @article.tags.each do |tag|
                  Badge(:outline, :sm) { tag.name }
                end
              end
            end
            if @article.body.present?
              p(class: "text-sm text-base-content/70 line-clamp-2") do
                plain @article.body.to_plain_text.truncate(150)
              end
            end
          end
        end
      end
    end
  end
end
