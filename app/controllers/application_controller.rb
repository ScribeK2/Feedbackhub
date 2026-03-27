class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_authentication

  helper_method :current_user

  layout -> { Layouts::ApplicationLayout }

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_authentication
    unless current_user
      redirect_to login_path, alert: "You must sign in to continue."
    end
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Admin access required."
    end
  end
end
