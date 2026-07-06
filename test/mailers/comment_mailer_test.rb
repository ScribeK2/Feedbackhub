# frozen_string_literal: true

require "test_helper"

class CommentMailerTest < ActionMailer::TestCase
  test "new_comment addresses the recipient with comment details and links" do
    submission = feedback_submissions(:high_priority)
    comment = submission.comments.create!(author: users(:regular), body: "Please review this one")
    email = CommentMailer.new_comment(users(:manager), comment)

    assert_equal [ users(:manager).email ], email.to
    assert_equal "New comment on feedback for Jane Doe", email.subject
    assert_match "Please review this one", email.body.encoded
    assert_match users(:regular).name, email.body.encoded
    assert_match "/feedback/#{submission.id}", email.body.encoded
    assert_match "/settings/subscriptions", email.body.encoded
  end
end
