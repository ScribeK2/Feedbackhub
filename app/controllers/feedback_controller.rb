class FeedbackController < ApplicationController
  def index
    @submissions = FeedbackSubmission.includes(:feedback_template).order(created_at: :desc)
    @submissions = @submissions.where(csr_name: params[:csr]) if params[:csr].present?
    @submissions = @submissions.where(submitted_by: params[:submitted_by]) if params[:submitted_by].present?
    @submissions = @submissions.search(params[:q]) if params[:q].present?

    render Feedback::IndexComponent.new(
      submissions: @submissions,
      filters: { q: params[:q], csr: params[:csr], submitted_by: params[:submitted_by] }
    )
  end

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
      data: submission_data(@template)
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

  def submission_data(template)
    allowed_keys = template.field_schema.flat_map do |field|
      keys = [ field["name"] ]
      keys << "#{field['name']}_other" if field["has_other"]
      keys
    end
    params.fetch(:data, {}).permit(*allowed_keys).to_h
  end
end
