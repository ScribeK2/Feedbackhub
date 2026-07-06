class SubscriptionsController < ApplicationController
  def update
    @submission = FeedbackSubmission.find(params[:feedback_id])
    subscribed = ActiveModel::Type::Boolean.new.cast(params[:subscribed])
    subscription = @submission.feedback_subscriptions.find_or_initialize_by(user: current_user)
    subscription.update!(subscribed: subscribed)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "subscription_toggle_#{@submission.id}",
          Comments::SubscriptionToggleComponent.new(submission: @submission, user: current_user)
        )
      end
      format.html do
        notice = subscribed ? "Subscribed to feedback." : "Unsubscribed from feedback."
        redirect_back fallback_location: settings_subscriptions_path, notice: notice
      end
    end
  end
end
