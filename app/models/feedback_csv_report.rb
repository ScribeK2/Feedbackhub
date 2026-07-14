# frozen_string_literal: true

require "csv"

# Builds the feedback-index CSV export. Fixed columns only — the per-template
# `data` JSON and rich-text `feedback_details` are intentionally excluded.
# Pure value object over an enumerable of FeedbackSubmission records.
class FeedbackCsvReport
  include CsvSafe

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
      csv_safe(submission.id),
      csv_safe(submission.created_at&.strftime("%Y-%m-%d %H:%M")),
      csv_safe(submission.feedback_template&.name),
      csv_safe(submission.csr_name),
      csv_safe(submission.feedback_type),
      csv_safe(submission.priority),
      csv_safe(submission.status),
      csv_safe(submission.ticket_number),
      csv_safe(submission.submitted_by)
    ]
  end
end
