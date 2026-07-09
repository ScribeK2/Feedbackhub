# frozen_string_literal: true

require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @submission = feedback_submissions(:high_priority)
  end

  test "requires authentication" do
    get feedback_comments_path(@submission)
    assert_redirected_to login_path
  end

  test "index renders the comments section" do
    sign_in_as_user
    @submission.comments.create!(author: users(:admin), body: "Existing comment")

    get feedback_comments_path(@submission)
    assert_response :success
    assert_match "Existing comment", response.body
    assert_match "comments_submission_#{@submission.id}", response.body
  end

  test "create adds a comment by the current user" do
    sign_in_as_user

    assert_difference -> { @submission.comments.count } do
      post feedback_comments_path(@submission), params: { comment: { body: "New comment" } }
    end
    assert_response :success
    assert_equal users(:regular), @submission.comments.chronological.last.author
  end

  test "create with a blank body re-renders the form with errors" do
    sign_in_as_user

    assert_no_difference -> { Comment.count } do
      post feedback_comments_path(@submission), params: { comment: { body: "" } }
    end
    assert_response :unprocessable_entity
    assert_match "can&#39;t be blank", response.body
  end

  test "author can fetch the edit form for their comment" do
    sign_in_as_user
    comment = @submission.comments.create!(author: users(:regular), body: "My comment")

    get edit_comment_path(comment)
    assert_response :success
    assert_match "comment[body]", response.body
    assert_match "My comment", response.body
  end

  test "non-author cannot fetch the edit form" do
    sign_in_as_user
    comment = @submission.comments.create!(author: users(:admin), body: "Not yours")

    get edit_comment_path(comment)
    assert_redirected_to root_path
  end

  test "admin cannot edit another user's comment" do
    sign_in_as_admin
    comment = @submission.comments.create!(author: users(:regular), body: "Author's words")

    patch comment_path(comment), params: { comment: { body: "Overwritten" } }
    assert_redirected_to root_path
    assert_equal "Author's words", comment.reload.body
  end

  test "author can update their comment" do
    sign_in_as_user
    comment = @submission.comments.create!(author: users(:regular), body: "Typo here")

    patch comment_path(comment), params: { comment: { body: "Typo fixed" } }
    assert_response :success
    assert_equal "Typo fixed", comment.reload.body
    assert_match "comment_#{comment.id}", response.body
  end

  test "update with a blank body re-renders the edit form" do
    sign_in_as_user
    comment = @submission.comments.create!(author: users(:regular), body: "Keep me")

    patch comment_path(comment), params: { comment: { body: "" } }
    assert_response :unprocessable_entity
    assert_equal "Keep me", comment.reload.body
  end

  test "author can delete their comment" do
    sign_in_as_user
    comment = @submission.comments.create!(author: users(:regular), body: "Regret")

    assert_difference "Comment.count", -1 do
      delete comment_path(comment)
    end
    assert_response :success
  end

  test "admin can delete any comment" do
    sign_in_as_admin
    comment = @submission.comments.create!(author: users(:regular), body: "Inappropriate")

    assert_difference "Comment.count", -1 do
      delete comment_path(comment)
    end
    assert_response :success
  end

  test "non-author non-admin cannot delete a comment" do
    sign_in_as_manager
    comment = @submission.comments.create!(author: users(:regular), body: "Protected")

    assert_no_difference "Comment.count" do
      delete comment_path(comment)
    end
    assert_redirected_to root_path
  end

  test "show returns the rendered comment for the cancel link" do
    sign_in_as_user
    comment = @submission.comments.create!(author: users(:regular), body: "Back to normal")

    get comment_path(comment)
    assert_response :success
    assert_match "Back to normal", response.body
    assert_no_match(/name="comment\[body\]"/, response.body)
  end
end
