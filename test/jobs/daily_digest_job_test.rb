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

  test "skips a manager with no new feedback" do
    manager = users(:manager)
    manager.update!(last_digest_sent_at: Time.current)

    assert_no_emails do
      DailyDigestJob.perform_now
    end
  end

  test "skips an empty-team manager (never a firehose)" do
    empty = User.create!(email: "empty2@test.com", name: "Empty", password: "password", role: "manager")
    assert_no_emails do
      DailyDigestJob.perform_now
    end
    assert_nil empty.reload.last_digest_sent_at
  end
end
