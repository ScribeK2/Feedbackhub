# frozen_string_literal: true

require "csv"

# Builds the feedback-index CSV export. Fixed columns only — the per-template
# `data` JSON and rich-text `feedback_details` are intentionally excluded.
# Pure value object over an enumerable of FeedbackSubmission records.
class FeedbackCsvReport
  HEADERS = %w[id created_at template csr_name feedback_type priority status ticket_number submitted_by].freeze

  def initialize(submissions)
    @submissions = submissions
  end

  def to_csv
    CSV.generate do |csv|
      csv << HEADERS
      @submissions.each { |submission| csv << row_for(submission) }
    end
  end

  def filename
    "feedback-#{Date.current.iso8601}.csv"
  end

  private

  def row_for(submission)
    [
      submission.id,
      submission.created_at&.strftime("%Y-%m-%d %H:%M"),
      submission.feedback_template&.name,
      submission.csr_name,
      submission.feedback_type,
      submission.priority,
      submission.status,
      submission.ticket_number,
      submission.submitted_by
    ]
  end
end
