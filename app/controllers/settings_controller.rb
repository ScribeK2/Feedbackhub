class SettingsController < ApplicationController
  def subscriptions
    render Settings::SubscriptionsComponent.new(
      subscriptions: current_user.feedback_subscriptions.subscribed
        .includes(feedback_submission: :feedback_template).order(created_at: :desc)
    )
  end
end
