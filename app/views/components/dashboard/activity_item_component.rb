# frozen_string_literal: true

module Dashboard
  class ActivityItemComponent < ApplicationComponent
    def initialize(item:, type:)
      @item = item
      @type = type
    end

    def view_template
      div(class: "flex items-center gap-3 p-3 rounded-lg bg-base-200/50 hover:bg-base-200 transition-colors") do
        render_type_badge
        render_content
        render_time
      end
    end

    private

    def render_type_badge
      Badge type_modifier, :sm, class: "whitespace-nowrap" do
        plain type_label
      end
    end

    def render_content
      div(class: "flex-1 min-w-0") do
        case @type
        when :feedback
          render_feedback_content
        when :article
          render_article_content
        when :update
          render_update_content
        end
      end
    end

    def render_feedback_content
      p(class: "text-sm font-medium truncate") do
        plain "#{@item.feedback_template.name} — #{@item.csr_name || 'Unknown CSR'}"
      end
      p(class: "text-xs text-base-content/60 truncate") do
        plain "Ticket: #{@item.ticket_number || '—'} | Priority: #{@item.priority || '—'}"
      end
    end

    def render_article_content
      p(class: "text-sm font-medium truncate") { @item.title }
      p(class: "text-xs text-base-content/60 truncate") do
        plain "by #{@item.author.name}"
      end
    end

    def render_update_content
      p(class: "text-sm font-medium truncate") do
        plain "Standup Update — #{@item.date.strftime('%b %d, %Y')}"
      end
      p(class: "text-xs text-base-content/60 truncate") do
        plain "by #{@item.author.name}"
        if @item.pinned?
          plain " "
          Badge(:primary, :xs) { "Pinned" }
        end
      end
    end

    def render_time
      span(class: "text-xs text-base-content/50 whitespace-nowrap") do
        plain time_ago_in_words(@item.created_at) + " ago"
      end
    end

    def type_label
      case @type
      when :feedback then "Feedback"
      when :article then "Article"
      when :update then "Update"
      end
    end

    def type_modifier
      case @type
      when :feedback then :primary
      when :article then :secondary
      when :update then :accent
      end
    end
  end
end
