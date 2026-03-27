# frozen_string_literal: true

module Articles
  class IndexComponent < ApplicationComponent
    def initialize(articles:)
      @articles = articles
    end

    def view_template
      div(class: "space-y-6") do
        render_header
        if @articles.empty?
          render_empty_state
        else
          render_grid
        end
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-center") do
        h1(class: "text-3xl font-bold") { "Knowledge Base" }
        Button(:primary, as: :a, href: new_article_path) { "New Article" }
      end
    end

    def render_grid
      div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4") do
        @articles.each do |article|
          render CardComponent.new(article: article)
        end
      end
    end

    def render_empty_state
      div(class: "text-center py-12") do
        p(class: "text-base-content/60 text-lg") { "No articles yet." }
        Button(:primary, as: :a, href: new_article_path, class: "mt-4") do
          plain "Create First Article"
        end
      end
    end
  end
end
