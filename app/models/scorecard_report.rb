# frozen_string_literal: true

# Aggregates feedback (issues) logged against a single CSR over a date range,
# plus the equal-length immediately-preceding window, for the manager scorecard.
#
# Pure value object: reads FeedbackSubmission via the shared `for_csrs` scope and
# computes breakdowns in Ruby. Feedback volume is low, and `impact` lives only in
# JSON `data`, so DB-side grouping is not uniformly available.
class ScorecardReport
  DEFAULT_RANGE_DAYS = 30
  WEEKLY_BUCKET_MAX_DAYS = 90

  attr_reader :date_range

  # Team rollup: one report over many CSRs. A per-CSR report is the set of
  # size one, so every public method below works unchanged for both.
  def self.for_team(csr_names, date_range: nil)
    new(csr_names: csr_names, date_range: date_range)
  end

  def initialize(csr_name: nil, csr_names: nil, date_range: nil)
    @csr_names = Array(csr_names || csr_name).map(&:to_s)
    @date_range = date_range || self.class.default_range
  end

  # Single-subject callers only (page title, CSV filename). Team reports do
  # not use this.
  def csr_name
    @csr_names.first.to_s
  end

  def self.default_range
    DEFAULT_RANGE_DAYS.days.ago.beginning_of_day..Time.current.end_of_day
  end

  def total_count
    @total_count ||= base.where(created_at: date_range).count
  end

  # All-time open items for this CSR (not period-bounded): a nudge, not a trend.
  def open_count
    @open_count ||= base.open.count
  end

  def previous_count
    @previous_count ||= base.where(created_at: previous_range).count
  end

  def delta
    total_count - previous_count
  end

  def severity_counts
    ordered_tally(current_submissions.map(&:priority), %w[High Medium Low])
  end

  def category_counts
    tally_desc(current_submissions.map(&:feedback_type))
  end

  def impact_counts
    tally_desc(current_submissions.map { |s| s.data["impact"] })
  end

  def status_counts
    ordered_tally(current_submissions.map(&:status), FeedbackSubmission::STATUSES)
  end

  def trend_buckets
    counts = Hash.new(0)
    current_submissions.each { |s| counts[bucket_key(s.created_at)] += 1 }
    bucket_starts.map { |start| { label: bucket_label(start), count: counts[start] } }
  end

  def recent(limit = 5)
    current_submissions.first(limit)
  end

  def empty?
    base.none?
  end

  def zero_in_period?
    total_count.zero?
  end

  private

  def base
    FeedbackSubmission.for_csrs(@csr_names)
  end

  def current_submissions
    @current_submissions ||= base.where(created_at: date_range).order(created_at: :desc).to_a
  end

  def previous_range
    length = date_range.end - date_range.begin
    (date_range.begin - length)...date_range.begin
  end

  def bucket_unit
    span_days = (date_range.end.to_date - date_range.begin.to_date).to_i
    span_days > WEEKLY_BUCKET_MAX_DAYS ? :month : :week
  end

  def bucket_key(time)
    t = time.to_time
    bucket_unit == :month ? t.beginning_of_month.to_date : t.beginning_of_week.to_date
  end

  def bucket_starts
    step = bucket_unit == :month ? 1.month : 1.week
    cursor = bucket_key(date_range.begin)
    last = bucket_key(date_range.end)
    starts = []
    while cursor <= last
      starts << cursor
      cursor += step
    end
    starts
  end

  def bucket_label(start)
    bucket_unit == :month ? start.strftime("%b") : start.strftime("%-m/%-d")
  end

  def ordered_tally(values, order)
    counts = values.compact.tally
    order.to_h { |key| [ key, counts.fetch(key, 0) ] }
  end

  def tally_desc(values)
    values.compact.tally.sort_by { |_label, count| -count }.to_h
  end
end
