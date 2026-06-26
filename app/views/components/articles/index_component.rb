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
        h1(class: "page-title") { "Knowledge Base" }
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
      render Shared::EmptyStateComponent.new(
        title: "No articles yet",
        description: "Knowledge base articles will show up here.",
        icon: :document
      )
    end
  end
end
