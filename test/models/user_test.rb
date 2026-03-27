# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user saves successfully" do
    user = User.new(
      email: "new@test.com",
      name: "New User",
      password: "password",
      password_confirmation: "password",
      role: "user"
    )
    assert user.save
  end

  test "requires email" do
    user = User.new(name: "Test", password: "password", role: "user")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires unique email" do
    existing = users(:admin)
    user = User.new(
      email: existing.email,
      name: "Duplicate",
      password: "password",
      role: "user"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "validates email format" do
    user = User.new(email: "not-an-email", name: "Test", password: "password", role: "user")
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "requires name" do
    user = User.new(email: "test@test.com", password: "password", role: "user")
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "requires valid role" do
    user = User.new(email: "test@test.com", name: "Test", password: "password", role: "superadmin")
    assert_not user.valid?
    assert_includes user.errors[:role], "is not included in the list"
  end

  test "defaults role to user" do
    user = User.new
    assert_equal "user", user.role
  end

  test "admin? returns true for admin role" do
    assert users(:admin).admin?
  end

  test "admin? returns false for user role" do
    assert_not users(:regular).admin?
  end

  test "authenticates with correct password" do
    user = users(:admin)
    assert user.authenticate("password")
  end

  test "rejects incorrect password" do
    user = users(:admin)
    assert_not user.authenticate("wrongpassword")
  end
end
