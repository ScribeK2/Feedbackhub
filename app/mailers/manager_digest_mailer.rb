class ManagerDigestMailer < ApplicationMailer
  def daily(manager, submissions)
    @manager = manager
    @submissions = submissions
    mail(to: manager.email, subject: "Your daily feedback digest (#{submissions.size} new)")
  end
end
