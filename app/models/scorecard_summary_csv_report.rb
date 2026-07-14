# frozen_string_literal: true

require "csv"

# Team-summary scorecard CSV: one row per CSR with roll-up metrics plus severity
# and status breakdowns. Consumes an array of ScorecardReport instances.
class ScorecardSummaryCsvReport
  include CsvSafe

  HEADERS = %w[csr_name total delta open high medium low s_open s_reviewed s_actioned s_dismissed].freeze

  def initialize(reports)
    @reports = reports
  end

  def to_csv
    CSV.generate do |csv|
      csv << HEADERS
      @reports.each { |report| csv << row_for(report) }
    end
  end

  def filename
    "scorecards-#{Date.current.iso8601}.csv"
  end

  private

  def row_for(report)
    severity = report.severity_counts
    status = report.status_counts
    [
      csv_safe(report.csr_name),
      csv_safe(report.total_count),
      csv_safe(report.delta),
      csv_safe(report.open_count),
      csv_safe(severity["High"]),
      csv_safe(severity["Medium"]),
      csv_safe(severity["Low"]),
      csv_safe(status["open"]),
      csv_safe(status["reviewed"]),
      csv_safe(status["actioned"]),
      csv_safe(status["dismissed"])
    ]
  end
end
