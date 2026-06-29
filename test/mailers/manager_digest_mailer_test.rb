# frozen_string_literal: true

require "test_helper"

class ManagerDigestMailerTest < ActionMailer::TestCase
  test "daily addresses the manager and lists submissions" do
    manager = users(:manager)
    submissions = FeedbackSubmission.for_csrs(manager.team_csr_names)
    email = ManagerDigestMailer.daily(manager, submissions)

    assert_equal [manager.email], email.to
    assert_match "Jane Doe", email.body.encoded
  end
end
