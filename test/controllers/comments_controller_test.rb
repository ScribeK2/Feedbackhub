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
end
