class SettingsController < ApplicationController
  def account
    render Settings::AccountComponent.new(user: current_user)
  end

  def update_profile
    if current_user.update(profile_params)
      redirect_to settings_account_path, notice: "Profile updated."
    else
      render Settings::AccountComponent.new(user: current_user), status: :unprocessable_entity
    end
  end

  def update_password
    unless current_user.authenticate(params.dig(:user, :current_password).to_s)
      return render Settings::AccountComponent.new(
        user: current_user, password_error: "Current password is incorrect."
      ), status: :unprocessable_entity
    end

    if password_params[:password].blank?
      return render Settings::AccountComponent.new(
        user: current_user, password_error: "New password can't be blank."
      ), status: :unprocessable_entity
    end

    if current_user.update(password_params)
      redirect_to settings_account_path, notice: "Password changed."
    else
      render Settings::AccountComponent.new(user: current_user), status: :unprocessable_entity
    end
  end

  def subscriptions
    render Settings::SubscriptionsComponent.new(
      subscriptions: current_user.feedback_subscriptions.subscribed
        .includes(feedback_submission: :feedback_template).order(created_at: :desc)
    )
  end

  private

  def profile_params
    params.require(:user).permit(:name, :email)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
