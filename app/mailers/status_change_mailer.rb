class StatusChangeMailer < ApplicationMailer
  def status_changed(recipient, status_change)
    @recipient = recipient
    @status_change = status_change
    @submission = status_change.feedback_submission
    mail(to: recipient.email,
         subject: "Feedback for #{@submission.csr_label} was #{status_change.verb}")
  end
end
