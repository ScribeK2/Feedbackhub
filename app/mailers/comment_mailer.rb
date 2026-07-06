class CommentMailer < ApplicationMailer
  def new_comment(recipient, comment)
    @recipient = recipient
    @comment = comment
    @submission = comment.feedback_submission
    subject_target = @submission.csr_name.presence || "a feedback submission"
    mail(to: recipient.email, subject: "New comment on feedback for #{subject_target}")
  end
end
