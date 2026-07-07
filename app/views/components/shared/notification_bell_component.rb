# frozen_string_literal: true

module Shared
  class NotificationBellComponent < ApplicationComponent
    def initialize(user:)
      @user = user
    end

    def view_template
      div(id: "notifications_bell") do
        unread_count = @user.notifications.unread.count

        Dropdown :end do |dropdown|
          dropdown.button :ghost, :sm, class: "indicator" do
            render_bell_icon
            if unread_count.positive?
              span(class: "badge badge-xs badge-primary indicator-item") { unread_count.to_s }
            end
          end
          dropdown.menu :base_100, class: "w-80 mt-2 shadow-lg" do |menu|
            render_items(menu)
          end
        end
      end
    end

    private

    def render_items(menu)
      notifications = @user.notifications.recent.includes(:event).limit(10)

      if notifications.empty?
        menu.item do
          span(class: "text-sm opacity-60") { "No notifications yet" }
        end
        return
      end

      notifications.each do |notification|
        menu.item do
          a(
            href: notification_path(notification),
            class: "flex flex-col items-start gap-0.5 #{'opacity-60' if notification.read?}"
          ) do
            span(class: "text-sm") { notification_text(notification) }
            span(class: "text-xs opacity-60") do
              plain time_ago_in_words(notification.created_at) + " ago"
            end
          end
        end
      end

      menu.item(class: "border-t border-base-300 mt-1 pt-1") do
        div(class: "flex justify-between items-center") do
          a(href: notifications_path, class: "text-sm") { "View all" }
          form(action: mark_all_read_notifications_path, method: "post", class: "inline") do
            input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
            button(type: "submit", class: "text-sm link link-hover") { "Mark all read" }
          end
        end
      end
    end

    def notification_text(notification)
      notification.event.notification_headline
    end

    def render_bell_icon
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        class: "h-5 w-5",
        fill: "none",
        viewBox: "0 0 24 24",
        stroke: "currentColor",
        stroke_width: "2"
      ) do |s|
        s.path(
          stroke_linecap: "round",
          stroke_linejoin: "round",
          d: "M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
        )
      end
    end
  end
end
