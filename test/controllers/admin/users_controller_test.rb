# frozen_string_literal: true

require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_admin
  end

  test "index lists all users" do
    get admin_users_path
    assert_response :success
  end

  test "new renders user form" do
    get new_admin_user_path
    assert_response :success
  end

  test "create saves valid user" do
    assert_difference "User.count", 1 do
      post admin_users_path, params: {
        user: {
          name: "New Person",
          email: "newperson@test.com",
          role: "user",
          password: "password",
          password_confirmation: "password"
        }
      }
    end
    assert_redirected_to admin_users_path
  end

  test "create with invalid params re-renders form" do
    assert_no_difference "User.count" do
      post admin_users_path, params: {
        user: { name: "", email: "", role: "user", password: "pw", password_confirmation: "pw" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "edit renders user form" do
    get edit_admin_user_path(users(:regular))
    assert_response :success
  end

  test "update modifies user" do
    user = users(:regular)
    patch admin_user_path(user), params: {
      user: { name: "Updated Name" }
    }
    assert_redirected_to admin_users_path
    user.reload
    assert_equal "Updated Name", user.name
  end

  test "destroy deletes user" do
    user = users(:regular)
    assert_difference "User.count", -1 do
      delete admin_user_path(user)
    end
    assert_redirected_to admin_users_path
  end

  test "cannot delete self" do
    admin = users(:admin)
    assert_no_difference "User.count" do
      delete admin_user_path(admin)
    end
    assert_redirected_to admin_users_path
  end

  test "regular user cannot access admin users" do
    delete logout_path
    sign_in_as_user
    get admin_users_path
    assert_redirected_to root_path
  end

  test "unauthenticated user is redirected to login" do
    delete logout_path
    get admin_users_path
    assert_redirected_to login_path
  end
end
