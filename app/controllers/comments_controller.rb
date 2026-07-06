class CommentsController < ApplicationController
  before_action :set_submission

  def index
    render Comments::SectionComponent.new(submission: @submission, user: current_user)
  end

  def create
    @comment = @submission.comments.new(comment_params.merge(author: current_user))

    if @comment.save
      render turbo_stream: [
        turbo_stream.replace(
          "comment_form_#{@submission.id}",
          Comments::FormComponent.new(submission: @submission)
        ),
        turbo_stream.replace(
          "subscription_toggle_#{@submission.id}",
          Comments::SubscriptionToggleComponent.new(submission: @submission, user: current_user)
        )
      ]
    else
      render turbo_stream: turbo_stream.replace(
        "comment_form_#{@submission.id}",
        Comments::FormComponent.new(submission: @submission, comment: @comment)
      ), status: :unprocessable_entity
    end
  end

  private

  def set_submission
    @submission = FeedbackSubmission.find(params[:feedback_id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
