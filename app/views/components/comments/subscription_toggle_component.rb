# frozen_string_literal: true

module Comments
  class SubscriptionToggleComponent < ApplicationComponent
    def initialize(submission:, user:)
      @submission = submission
      @user = user
    end

    def view_template
      subscribed = @submission.subscribed?(@user)

      span(id: "subscription_toggle_#{@submission.id}") do
        form(action: feedback_subscription_path(@submission), method: "post", class: "inline") do
          input(type: "hidden", name: "_method", value: "patch")
          input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
          input(type: "hidden", name: "subscribed", value: (!subscribed).to_s)
          button(
            type: "submit",
            class: "btn btn-ghost btn-xs",
            title: subscribed ? "Stop receiving notifications for this feedback" : "Get notified about new comments"
          ) do
            plain subscribed ? "Unsubscribe" : "Subscribe"
          end
        end
      end
    end
  end
end
