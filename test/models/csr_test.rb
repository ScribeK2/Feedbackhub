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

  test "strips surrounding whitespace from name" do
    csr = Csr.create!(name: "  Priya Patel  ")
    assert_equal "Priya Patel", csr.name
    assert_equal csr, Csr.lookup("priya patel")
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

  test "renaming rewrites submission csr_name, data json, and memberships" do
    submission = feedback_submissions(:high_priority)
    membership = team_memberships(:manager_jane)

    csrs(:jane_doe).update!(name: "Jane A. Doe")

    assert_equal "Jane A. Doe", submission.reload.csr_name
    assert_equal "Jane A. Doe", submission.data["csr"]
    assert_equal "Jane A. Doe", membership.reload.csr_name
  end

  test "rename rejects a name already registered to another CSR" do
    csr = csrs(:jane_doe)
    assert_not csr.update(name: "test csr")
    assert_includes csr.errors[:name], "has already been taken"
    assert_equal "Jane Doe", csr.reload.name
    assert_equal "Jane Doe", feedback_submissions(:high_priority).reload.csr_name
  end

  test "toggling active does not rewrite references" do
    csrs(:jane_doe).update!(active: false)
    assert_equal "Jane Doe", feedback_submissions(:high_priority).reload.csr_name
  end

  test "merge_into! repoints references and removes the source" do
    source = csrs(:jane_doe)
    submission = feedback_submissions(:high_priority)
    membership = team_memberships(:manager_jane)

    source.merge_into!(csrs(:test_csr))

    assert_equal "Test CSR", submission.reload.csr_name
    assert_equal "Test CSR", submission.data["csr"]
    assert_equal "Test CSR", membership.reload.csr_name
    assert_not Csr.exists?(source.id)
  end

  test "merge_into! drops memberships that would collide" do
    kept = users(:manager).team_memberships.create!(csr_name: "Test CSR")
    jane_membership_id = team_memberships(:manager_jane).id

    assert_difference "TeamMembership.count", -1 do
      csrs(:jane_doe).merge_into!(csrs(:test_csr))
    end
    assert TeamMembership.exists?(kept.id)
    assert_not TeamMembership.exists?(jane_membership_id)
  end

  test "merge_into! refuses to merge into itself" do
    assert_raises(ArgumentError) { csrs(:jane_doe).merge_into!(csrs(:jane_doe)) }
  end

  test "referenced? reflects submissions and memberships" do
    assert csrs(:jane_doe).referenced?
    assert_not csrs(:former_employee).referenced?
  end

  test "submission_count and membership_count match case-insensitively" do
    assert_equal 2, csrs(:jane_doe).submission_count
    assert_equal 1, csrs(:jane_doe).membership_count
  end
end
