# frozen_string_literal: true

module Notifications
  class IndexComponent < ApplicationComponent
    def initialize(notifications:)
      @notifications = notifications
    end

    def view_template
      div(class: "max-w-2xl mx-auto") do
        div(class: "flex items-center justify-between mb-6") do
          h1(class: "text-2xl font-bold") { "Notifications" }
          if @notifications.any?
            form(action: mark_all_read_notifications_path, method: "post") do
              input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
              button(type: "submit", class: "btn btn-ghost btn-sm") { "Mark all read" }
            end
          end
        end

        if @notifications.empty?
          Card :base_100, class: "shadow" do |card|
            card.body do
              p(class: "text-base-content/60 text-center py-4") do
                plain "No notifications yet. You'll be notified when someone comments on a feedback you follow."
              end
            end
          end
        else
          Card :base_100, class: "shadow" do |card|
            card.body class: "p-2" do
              @notifications.each { |notification| render_notification(notification) }
            end
          end
        end
      end
    end

    private

    def render_notification(notification)
      comment = notification.comment
      target = comment.feedback_submission.csr_name.presence || "a feedback submission"

      a(
        href: notification_path(notification),
        class: "flex items-start justify-between gap-3 p-3 rounded hover:bg-base-200 #{notification.read? ? 'opacity-60' : ''}"
      ) do
        div do
          p(class: "text-sm font-medium") do
            plain "#{comment.author.name} commented on feedback for #{target}"
          end
          p(class: "text-sm text-base-content/70 line-clamp-2") { comment.body }
        end
        div(class: "flex flex-col items-end gap-1 shrink-0") do
          span(class: "text-xs text-base-content/50") do
            plain time_ago_in_words(notification.created_at) + " ago"
          end
          unless notification.read?
            span(class: "badge badge-xs badge-primary")
          end
        end
      end
    end
  end
end
