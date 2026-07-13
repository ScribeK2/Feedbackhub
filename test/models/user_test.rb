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

  test "accepts manager role" do
    user = User.new(email: "m@test.com", name: "Mgr", password: "password", role: "manager")
    assert user.valid?
  end

  test "manager? returns true for manager role" do
    assert users(:manager).manager?
  end

  test "manager? returns false for non-manager roles" do
    assert_not users(:admin).manager?
    assert_not users(:regular).manager?
  end

  test "team_csr_names lists the manager's CSR names" do
    assert_equal [ "Jane Doe" ], users(:manager).team_csr_names
  end

  test "team_scoped? true for manager with memberships" do
    assert users(:manager).team_scoped?
  end

  test "team_scoped? false for admin and empty-team manager" do
    assert_not users(:admin).team_scoped?
    empty = User.create!(email: "empty@test.com", name: "Empty", password: "password", role: "manager")
    assert_not empty.team_scoped?
  end

  test "stream_for namespaces the channel for scoped managers" do
    assert_equal "dashboard:#{users(:manager).id}", users(:manager).stream_for("dashboard")
    assert_equal "dashboard", users(:admin).stream_for("dashboard")
  end

  test "managers_for returns managers whose team includes the csr name (case-insensitive)" do
    assert_includes User.managers_for("jane doe"), users(:manager)
    assert_empty User.managers_for("Nobody")
  end

  test "password shorter than 8 characters is invalid" do
    user = users(:regular)
    user.password = "short"
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "password of 8 or more characters is valid" do
    user = users(:regular)
    user.password = "longenough"
    assert user.valid?
  end

  test "update that does not touch password is unaffected by length rule" do
    user = users(:regular)
    user.name = "Renamed"
    assert user.valid?
  end
end
