# frozen_string_literal: true

require "test_helper"

class DailyDigestJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "emails a manager with new team feedback and advances the watermark" do
    manager = users(:manager) # team: "Jane Doe", has fixture feedback
    manager.update!(last_digest_sent_at: 1.year.ago)

    assert_emails 1 do
      DailyDigestJob.perform_now
    end
    assert_not_nil manager.reload.last_digest_sent_at
    assert_operator manager.last_digest_sent_at, :>, 1.minute.ago
  end

  test "sends the digest when items are still open even with no new feedback" do
    manager = users(:manager)
    manager.update!(last_digest_sent_at: Time.current)

    assert_emails 1 do
      DailyDigestJob.perform_now
    end
  end

  test "skips a manager with no new feedback and nothing open" do
    manager = users(:manager)
    manager.update!(last_digest_sent_at: Time.current)
    FeedbackSubmission.for_csrs(manager.team_csr_names).update_all(status: "dismissed")

    assert_no_emails do
      DailyDigestJob.perform_now
    end
  end

  test "skips an empty-team manager (never a firehose)" do
    users(:manager).update!(last_digest_sent_at: Time.current)
    FeedbackSubmission.for_csrs(users(:manager).team_csr_names).update_all(status: "dismissed")
    empty = User.create!(email: "empty2@test.com", name: "Empty", password: "password", role: "manager")
    assert_no_emails do
      DailyDigestJob.perform_now
    end
    assert_nil empty.reload.last_digest_sent_at
  end
end
