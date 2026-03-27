# frozen_string_literal: true

require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "login page renders successfully" do
    get login_path
    assert_response :success
  end

  test "login with valid credentials signs in and redirects" do
    user = users(:admin)
    post login_path, params: { email: user.email, password: "password" }
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "login with invalid credentials re-renders login" do
    post login_path, params: { email: "wrong@test.com", password: "bad" }
    assert_response :unprocessable_entity
  end

  test "login with wrong password re-renders login" do
    user = users(:admin)
    post login_path, params: { email: user.email, password: "wrongpassword" }
    assert_response :unprocessable_entity
  end

  test "logout clears session and redirects to login" do
    user = users(:admin)
    post login_path, params: { email: user.email, password: "password" }

    delete logout_path
    assert_redirected_to login_path

    get root_path
    assert_redirected_to login_path
  end

  test "unauthenticated user is redirected to login" do
    get root_path
    assert_redirected_to login_path
  end
end
