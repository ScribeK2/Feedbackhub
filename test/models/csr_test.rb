# frozen_string_literal: true

require "test_helper"

class CsrTest < ActiveSupport::TestCase
  test "valid with a unique name" do
    assert Csr.new(name: "Priya Patel").valid?
  end

  test "requires a name" do
    csr = Csr.new(name: "")
    assert_not csr.valid?
    assert_includes csr.errors[:name], "can't be blank"
  end

  test "rejects duplicate names case-insensitively" do
    csr = Csr.new(name: "jane doe")
    assert_not csr.valid?
    assert_includes csr.errors[:name], "has already been taken"
  end

  test "active scope excludes inactive CSRs" do
    assert_includes Csr.active, csrs(:jane_doe)
    assert_not_includes Csr.active, csrs(:former_employee)
  end

  test "lookup matches case-insensitively and strips whitespace" do
    assert_equal csrs(:jane_doe), Csr.lookup("  jane DOE ")
  end

  test "lookup returns nil for blank or unknown names" do
    assert_nil Csr.lookup(nil)
    assert_nil Csr.lookup("")
    assert_nil Csr.lookup("Nobody Registered")
  end

  test "user link is optional and assignable" do
    csr = csrs(:jane_doe)
    assert_nil csr.user
    csr.update!(user: users(:regular))
    assert_equal users(:regular), csr.reload.user
  end
end
