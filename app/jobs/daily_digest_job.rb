class DailyDigestJob < ApplicationJob
  queue_as :default

  def perform
    User.where(role: "manager").find_each do |manager|
      names = manager.team_csr_names
      next if names.empty?

      since = manager.last_digest_sent_at || manager.created_at
      now = Time.current
      submissions = FeedbackSubmission.for_csrs(names)
        .where("created_at > ? AND created_at <= ?", since, now)
        .order(created_at: :desc)
      next if submissions.empty?

      begin
        ManagerDigestMailer.daily(manager, submissions).deliver_now
        manager.update!(last_digest_sent_at: now)
      rescue => e
        Rails.logger.error("DailyDigestJob failed for manager #{manager.id}: #{e.message}")
      end
    end
  end
end
