class FeedbackSubmission < ApplicationRecord
  belongs_to :feedback_template
  has_rich_text :feedback_details

  validates :data, presence: true

  before_save :extract_grouping_fields

  after_create_commit do
    broadcast_prepend_to "feedback_submissions",
      target: "submissions",
      html: ApplicationController.render(Feedback::CardComponent.new(submission: self))
  end

  private

  def extract_grouping_fields
    self.csr_name = data["csr"].presence
    self.submitted_by = data["submitted_by"].presence
  end
end
