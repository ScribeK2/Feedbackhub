class HubController < ApplicationController
  def index
    @submissions = FeedbackSubmission.includes(:feedback_template).order(created_at: :desc)
    @grouped_by_csr = @submissions.group_by(&:csr_name)
    @grouped_by_submitter = @submissions.group_by(&:submitted_by)

    render Hub::IndexComponent.new(
      submissions: @submissions,
      grouped_by_csr: @grouped_by_csr,
      grouped_by_submitter: @grouped_by_submitter
    )
  end
end
