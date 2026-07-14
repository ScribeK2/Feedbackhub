# frozen_string_literal: true

require "csv"

# Single-CSR scorecard CSV in long ("tidy") format: section,label,count. Keeps a
# fixed 3-column header while the per-section breakdowns vary in length.
class ScorecardDetailCsvReport
  include CsvSafe

  HEADERS = %w[section label count].freeze

  def initialize(report)
    @report = report
  end

  def to_csv
    CSV.generate do |csv|
      csv << HEADERS
      append(csv, "severity", @report.severity_counts)
      append(csv, "category", @report.category_counts)
      append(csv, "impact", @report.impact_counts)
      append(csv, "status", @report.status_counts)
      @report.trend_buckets.each { |bucket| csv << [ "trend", csv_safe(bucket[:label]), csv_safe(bucket[:count]) ] }
    end
  end

  def filename
    "scorecard-#{@report.csr_name.parameterize}-#{Date.current.iso8601}.csv"
  end

  private

  def append(csv, section, counts)
    counts.each { |label, count| csv << [ section, csv_safe(label), csv_safe(count) ] }
  end
end
