# frozen_string_literal: true

require "test_helper"

class TeamMembershipTest < ActiveSupport::TestCase
  test "valid membership saves" do
    m = TeamMembership.new(manager: users(:manager), csr_name: "New CSR")
    assert m.save
  end

  test "requires csr_name" do
    m = TeamMembership.new(manager: users(:manager))
    assert_not m.valid?
    assert_includes m.errors[:csr_name], "can't be blank"
  end

  test "csr_name unique per manager, case-insensitive" do
    dup = TeamMembership.new(manager: users(:manager), csr_name: "jane doe")
    assert_not dup.valid?
    assert_includes dup.errors[:csr_name], "has already been taken"
  end

  test "belongs to a manager" do
    assert_equal users(:manager), team_memberships(:manager_jane).manager
  end

  test "for_csr matches case-insensitively" do
    assert_includes TeamMembership.for_csr("JANE DOE"), team_memberships(:manager_jane)
  end
end
