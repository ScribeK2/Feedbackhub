# frozen_string_literal: true

require "test_helper"

class ManagerDigestMailerTest < ActionMailer::TestCase
  test "daily lists new submissions and still-open items" do
    manager = users(:manager)
    submissions = FeedbackSubmission.for_csrs(manager.team_csr_names)
    email = ManagerDigestMailer.daily(manager, submissions, submissions.open.order(created_at: :asc))

    assert_equal [ manager.email ], email.to
    assert_match "Jane Doe", email.body.encoded
    assert_match "TK-001", email.body.encoded
    assert_match "TK-002", email.body.encoded
    assert_match "Still open", email.body.encoded
  end
end
