# frozen_string_literal: true

require "test_helper"

class StatusChangeMailerTest < ActionMailer::TestCase
  test "status_changed describes the transition" do
    submission = feedback_submissions(:high_priority)
    change = submission.transition_to("actioned", actor: users(:manager), note: "Coached on call handling")
    email = StatusChangeMailer.status_changed(users(:regular), change)

    assert_equal [ users(:regular).email ], email.to
    assert_match "Jane Doe", email.subject
    assert_match "marked actioned", email.subject
    assert_match "Coached on call handling", email.body.encoded
  end
end
