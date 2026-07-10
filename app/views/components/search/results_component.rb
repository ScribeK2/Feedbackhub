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
            plain "No results found"
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
        render_feedback_result(result[:record]) { render_snippet(result) }
      when :article
        render_article_result(result[:record]) { render_snippet(result) }
      end
    end

    def render_feedback_result(submission, &block)
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
        yield if block
      end
    end

    def render_article_result(article, &block)
      a(href: article_path(article), class: "block p-3 hover:bg-base-200 transition-colors") do
        div(class: "flex items-center gap-2") do
          Badge(:secondary, :xs) { "Article" }
          span(class: "text-sm font-medium truncate") { article.title }
        end
        p(class: "text-xs text-base-content/60 mt-1") do
          plain "by #{article.author.name}"
        end
        yield if block
      end
    end

    SENTINEL_SPLIT = /(#{SearchEntry::SNIPPET_START}|#{SearchEntry::SNIPPET_END})/

    def render_snippet(result)
      return if result[:snippet].blank?

      p(class: "text-xs text-base-content/70 mt-1 truncate") do
        if result[:source]
          span(class: "italic text-base-content/50") { "#{result[:source]}: " }
        end
        in_mark = false
        result[:snippet].split(SENTINEL_SPLIT).each do |part|
          case part
          when SearchEntry::SNIPPET_START then in_mark = true
          when SearchEntry::SNIPPET_END then in_mark = false
          else
            in_mark ? mark(class: "bg-warning/40 rounded px-0.5") { part } : plain(part)
          end
        end
      end
    end
  end
end
