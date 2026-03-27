# frozen_string_literal: true

module Search
  class ResultsComponent < ApplicationComponent
    def initialize(results:, query:)
      @results = results
      @query = query
    end

    def view_template
      div(id: "search_results") do
        if @query.blank?
          # Empty — nothing to show
        elsif @results.empty?
          div(class: "p-4 text-sm text-base-content/60") do
            plain "No results for \"#{@query}\""
          end
        else
          div(class: "divide-y divide-base-300") do
            @results.each { |r| render_result(r) }
          end
        end
      end
    end

    private

    def render_result(result)
      case result[:type]
      when :feedback
        render_feedback_result(result[:record])
      when :article
        render_article_result(result[:record])
      end
    end

    def render_feedback_result(submission)
      a(href: feedback_path(submission), class: "block p-3 hover:bg-base-200 transition-colors") do
        div(class: "flex items-center gap-2") do
          Badge(:primary, :xs) { "Feedback" }
          span(class: "text-sm font-medium truncate") do
            plain "#{submission.feedback_template.name} — #{submission.csr_name || 'Unknown'}"
          end
        end
        p(class: "text-xs text-base-content/60 mt-1") do
          plain "Ticket: #{submission.ticket_number || '—'} | #{submission.priority || '—'} priority"
        end
      end
    end

    def render_article_result(article)
      a(href: article_path(article), class: "block p-3 hover:bg-base-200 transition-colors") do
        div(class: "flex items-center gap-2") do
          Badge(:secondary, :xs) { "Article" }
          span(class: "text-sm font-medium truncate") { article.title }
        end
        p(class: "text-xs text-base-content/60 mt-1") do
          plain "by #{article.author.name}"
        end
      end
    end
  end
end
