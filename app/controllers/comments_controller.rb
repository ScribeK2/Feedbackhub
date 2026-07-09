class CommentsController < ApplicationController
  before_action :set_submission, only: [ :index, :create ]
  before_action :set_comment, only: [ :show, :edit, :update, :destroy ]
  before_action :require_author, only: [ :edit, :update ]
  before_action :require_author_or_admin, only: [ :destroy ]

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

  def show
    render turbo_stream: turbo_stream.replace(
      "comment_#{@comment.id}",
      Comments::CommentComponent.new(comment: @comment, user: current_user)
    )
  end

  def edit
    render turbo_stream: turbo_stream.replace(
      "comment_#{@comment.id}",
      Comments::EditFormComponent.new(comment: @comment)
    )
  end

  def update
    if @comment.update(comment_params)
      render turbo_stream: turbo_stream.replace(
        "comment_#{@comment.id}",
        Comments::CommentComponent.new(comment: @comment, user: current_user)
      )
    else
      render turbo_stream: turbo_stream.replace(
        "comment_#{@comment.id}",
        Comments::EditFormComponent.new(comment: @comment)
      ), status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    render turbo_stream: turbo_stream.remove("comment_#{@comment.id}")
  end

  private

  def set_submission
    @submission = FeedbackSubmission.find(params[:feedback_id])
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def require_author
    unless @comment.author == current_user
      redirect_to root_path, alert: "You can only edit your own comments."
    end
  end

  def require_author_or_admin
    unless @comment.author == current_user || current_user&.admin?
      redirect_to root_path, alert: "You can only delete your own comments."
    end
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
