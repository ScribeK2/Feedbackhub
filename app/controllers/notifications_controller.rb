class NotificationsController < ApplicationController
  def index
    render Notifications::IndexComponent.new(
      notifications: current_user.notifications.recent.includes(:event).limit(50)
    )
  end

  def show
    notification = current_user.notifications.find(params[:id])
    notification.mark_read!
    redirect_to feedback_path(notification.event.feedback_submission)
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_back fallback_location: notifications_path
  end
end
