class CommentMailer < ApplicationMailer
  def new_comment(recipient, comment)
    @recipient = recipient
    @comment = comment
    @submission = comment.feedback_submission
    mail(to: recipient.email, subject: "New comment on feedback for #{@submission.csr_label}")
  end
end
