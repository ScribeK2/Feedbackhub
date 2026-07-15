class ScorecardsController < ApplicationController
  include DateRangeParams

  before_action :require_manager_or_admin

  def index
    names = accessible_csr_names
    reports = ordered_reports(names)

    respond_to do |format|
      format.html { render Scorecards::IndexComponent.new(tiles: reports.map { |report| tile_for(report) }) }
      format.csv do
        report = ScorecardSummaryCsvReport.new(reports)
        send_data report.to_csv, filename: report.filename, type: "text/csv"
      end
    end
  end

  def show
    csr = params[:csr].to_s
    unless authorized_for?(csr)
      redirect_to scorecards_path, alert: "That CSR is not on your team." and return
    end

    report = ScorecardReport.new(csr_name: csr, date_range: requested_range)
    respond_to do |format|
      format.html { render Scorecards::ShowComponent.new(report: report) }
      format.csv do
        csv = ScorecardDetailCsvReport.new(report)
        send_data csv.to_csv, filename: csv.filename, type: "text/csv"
      end
    end
  end

  private

  def require_manager_or_admin
    unless current_user&.manager? || current_user&.admin?
      redirect_to root_path, alert: "Manager access required."
    end
  end

  def accessible_csr_names
    if current_user.admin?
      FeedbackSubmission.where.not(csr_name: nil).distinct.pluck(:csr_name).sort
    else
      current_user.team_csr_names.sort
    end
  end

  def authorized_for?(csr)
    return false if csr.blank?
    return true if current_user.admin?

    current_user.team_csr_names.any? { |name| name.casecmp?(csr) }
  end

  # Ranked by within-CSR movement, worst first. Sorting by total_count is
  # forbidden: with no ticket-volume denominator that is a punitive
  # leaderboard, which the scorecard spec explicitly refuses. The name
  # tie-break is load-bearing — most rows sit at delta 0, and without it the
  # list reshuffles between reloads.
  def ordered_reports(names)
    names.map { |name| ScorecardReport.new(csr_name: name, date_range: requested_range) }
         .sort_by { |report| [ -report.delta, report.csr_name.downcase ] }
  end

  def tile_for(report)
    { csr_name: report.csr_name, count: report.total_count, delta: report.delta, open_count: report.open_count }
  end

  def requested_range
    @requested_range ||= date_range_from(params[:start], params[:end]) || ScorecardReport.default_range
  end
end
