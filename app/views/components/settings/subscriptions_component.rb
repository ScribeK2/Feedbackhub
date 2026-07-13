# frozen_string_literal: true

module Settings
  class SubscriptionsComponent < ApplicationComponent
    def initialize(subscriptions:)
      @subscriptions = subscriptions
    end

    def view_template
      div(class: "max-w-2xl mx-auto") do
        render Settings::TabsComponent.new(active: :subscriptions)
        h1(class: "text-2xl font-bold mb-2") { "Subscriptions" }
        p(class: "text-base-content/60 mb-6") do
          plain "Feedback submissions you get comment notifications for. " \
            "Managers are automatically notified about their team's feedback " \
            "and can unsubscribe from individual submissions on the feedback itself."
        end

        if @subscriptions.empty?
          Card :base_100, class: "shadow" do |card|
            card.body do
              p(class: "text-base-content/60 text-center py-4") do
                plain "No subscriptions. Submitting or commenting on a feedback subscribes you automatically."
              end
            end
          end
        else
          Card :base_100, class: "shadow" do |card|
            card.body class: "p-2" do
              @subscriptions.each { |subscription| render_subscription(subscription) }
            end
          end
        end
      end
    end

    private

    def render_subscription(subscription)
      submission = subscription.feedback_submission

      div(class: "flex items-center justify-between gap-3 p-3 rounded hover:bg-base-200") do
        a(href: feedback_path(submission), class: "min-w-0") do
          p(class: "text-sm font-medium truncate") do
            plain submission.feedback_template.name
            plain " — #{submission.csr_name}" if submission.csr_name.present?
          end
          p(class: "text-xs text-base-content/50") do
            plain "Ticket #{submission.ticket_number || '—'} · submitted #{time_ago_in_words(submission.created_at)} ago"
          end
        end
        form(action: feedback_subscription_path(submission), method: "post", class: "shrink-0", data: { turbo: "false" }) do
          input(type: "hidden", name: "_method", value: "patch")
          input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
          input(type: "hidden", name: "subscribed", value: "false")
          button(type: "submit", class: "btn btn-ghost btn-xs") { "Unsubscribe" }
        end
      end
    end
  end
end
