class StatusesController < ApplicationController
  def update
    @submission = FeedbackSubmission.find(params[:feedback_id])

    unless @submission.triagable_by?(current_user)
      redirect_to feedback_index_path, alert: "You are not allowed to triage this feedback." and return
    end

    change = @submission.transition_to(params[:to_status], actor: current_user, note: params[:note])

    if change.persisted?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "triage_submission_#{@submission.id}",
              Feedback::TriageSectionComponent.new(submission: @submission, user: current_user)
            ),
            turbo_stream.update(
              "submission_status_badge_#{@submission.id}",
              Feedback::StatusBadgeComponent.new(submission: @submission, size: :lg)
            )
          ]
        end
        format.html { redirect_to feedback_path(@submission), notice: "Status updated." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "triage_submission_#{@submission.id}",
            Feedback::TriageSectionComponent.new(submission: @submission, user: current_user, failed_change: change)
          ), status: :unprocessable_entity
        end
        format.html { redirect_to feedback_path(@submission), alert: change.errors.full_messages.to_sentence }
      end
    end
  end
end
