class FeedbackController < ApplicationController
  before_action :require_admin, only: [ :edit, :update, :destroy ]
  before_action :set_submission, only: [ :edit, :update, :destroy ]

  def index
    @submissions = team_scoped(FeedbackSubmission.includes(:feedback_template, status_changes: :actor)).order(created_at: :desc)
    @submissions = @submissions.where(csr_name: params[:csr]) if params[:csr].present?
    @submissions = @submissions.where(submitted_by: params[:submitted_by]) if params[:submitted_by].present?
    @submissions = @submissions.search(params[:q]) if params[:q].present?
    @submissions = @submissions.with_status(params[:status]) if params[:status].present?
    @submissions = @submissions.by_priority(params[:priority]) if params[:priority].present?

    render Feedback::IndexComponent.new(
      submissions: @submissions,
      filters: { q: params[:q], csr: params[:csr], submitted_by: params[:submitted_by], status: params[:status], priority: params[:priority] }
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
      submitter: current_user,
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
    render Hub::SubmissionModalComponent.new(submission: @submission, open: true)
  end

  def edit
    render Feedback::FormComponent.new(
      templates: [],
      selected_template: @submission.feedback_template,
      submission: @submission
    )
  end

  def update
    template = @submission.feedback_template
    previous_csr = @submission.csr_name
    @submission.data = submission_data(template)

    if params[:feedback_submission]&.key?(:feedback_details)
      @submission.feedback_details = params[:feedback_submission][:feedback_details]
    end

    if @submission.save
      @submission.broadcast_correction(previous_csr)
      redirect_to feedback_index_path, notice: "Feedback updated."
    else
      render Feedback::FormComponent.new(
        templates: [],
        selected_template: template,
        submission: @submission
      ), status: :unprocessable_entity
    end
  end

  def destroy
    @submission.destroy
    redirect_to feedback_index_path, notice: "Feedback deleted."
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

  def set_submission
    @submission = FeedbackSubmission.find(params[:id])
  end

  def submission_data(template)
    allowed_keys = template.field_schema.flat_map do |field|
      keys = [ field["name"] ]
      keys << "#{field['name']}_other" if field["has_other"]
      keys
    end
    params.fetch(:data, {}).permit(*allowed_keys).to_h
  end
end
