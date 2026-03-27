class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: %i[new create]

  layout -> { Layouts::ApplicationLayout }

  def new
    render Sessions::LoginComponent.new
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: "Signed in successfully."
    else
      flash.now[:error] = "Invalid email or password."
      render Sessions::LoginComponent.new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Signed out successfully."
  end
end
