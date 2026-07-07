class ManagerDigestMailer < ApplicationMailer
  def daily(manager, submissions, open_submissions)
    @manager = manager
    @submissions = submissions
    @open_submissions = open_submissions
    mail(to: manager.email, subject: "Your daily feedback digest (#{submissions.size} new)")
  end
end
