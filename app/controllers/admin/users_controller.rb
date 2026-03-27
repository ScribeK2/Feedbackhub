module Admin
  class UsersController < ApplicationController
    before_action :require_admin
    before_action :set_user, only: %i[edit update destroy]

    def index
      @users = User.order(:name)
      render Admin::UserListComponent.new(users: @users)
    end

    def new
      @user = User.new
      render Admin::UserFormComponent.new(user: @user)
    end

    def create
      @user = User.new(user_params)

      if @user.save
        redirect_to admin_users_path, notice: "User created successfully!"
      else
        render Admin::UserFormComponent.new(user: @user), status: :unprocessable_entity
      end
    end

    def edit
      render Admin::UserFormComponent.new(user: @user)
    end

    def update
      if @user.update(user_params.reject { |_, v| v.blank? })
        redirect_to admin_users_path, notice: "User updated successfully!"
      else
        render Admin::UserFormComponent.new(user: @user), status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "You cannot delete yourself."
      else
        @user.destroy
        redirect_to admin_users_path, notice: "User deleted."
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email, :name, :role, :password, :password_confirmation)
    end
  end
end
