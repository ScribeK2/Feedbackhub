class FeedbackController < ApplicationController
  def new
    @templates = FeedbackTemplate.all
    @selected_template = FeedbackTemplate.find_by(id: params[:template_id])

    render Feedback::FormComponent.new(
      templates: @templates,
      selected_template: @selected_template
    )
  end

  def create
    @template = FeedbackTemplate.find(params[:feedback_template_id])
    @submission = FeedbackSubmission.new(
      feedback_template: @template,
      data: submission_data
    )

    if params.dig(:feedback_submission, :feedback_details).present?
      @submission.feedback_details = params[:feedback_submission][:feedback_details]
    end

    if @submission.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "feedback_form",
            Feedback::SuccessComponent.new
          )
        end
        format.html { redirect_to hub_path, notice: "Feedback submitted successfully!" }
      end
    else
      @templates = FeedbackTemplate.all
      render Feedback::FormComponent.new(
        templates: @templates,
        selected_template: @template,
        submission: @submission
      ), status: :unprocessable_entity
    end
  end

  def show
    @submission = FeedbackSubmission.find(params[:id])
    render Hub::SubmissionModalComponent.new(submission: @submission)
  end

  def form
    @templates = FeedbackTemplate.all
    @selected_template = FeedbackTemplate.find_by(id: params[:template_id])

    render turbo_stream: turbo_stream.replace(
      "feedback_form",
      Feedback::FormComponent.new(
        templates: @templates,
        selected_template: @selected_template
      )
    )
  end

  private

  def submission_data
    params.fetch(:data, {}).permit!.to_h
  end
end
