# frozen_string_literal: true

require "test_helper"

class UpdatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_user
  end

  test "index renders updates" do
    get updates_path
    assert_response :success
  end

  test "create saves valid update" do
    assert_difference "Update.count", 1 do
      post updates_path, params: {
        update: { date: "2026-03-26", body: "Standup notes", pinned: "0" }
      }
    end
    assert_redirected_to updates_path
  end

  test "create with missing date re-renders" do
    assert_no_difference "Update.count" do
      post updates_path, params: {
        update: { date: "", body: "Content" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "update toggles pin status" do
    update = updates(:archived_standup)
    assert_not update.pinned?

    patch update_path(update)
    update.reload
    assert update.pinned?
  end

  test "regular user can pin and unpin" do
    update = updates(:pinned_standup)
    patch update_path(update)
    update.reload
    assert_not update.pinned?
  end

  test "regular user cannot delete update" do
    assert_no_difference "Update.count" do
      delete update_path(updates(:archived_standup))
    end
    assert_redirected_to root_path
  end

  test "admin can delete update" do
    delete logout_path
    sign_in_as_admin
    assert_difference "Update.count", -1 do
      delete update_path(updates(:archived_standup))
    end
    assert_redirected_to updates_path
  end

  test "unauthenticated user is redirected to login" do
    delete logout_path
    get updates_path
    assert_redirected_to login_path
  end
end
