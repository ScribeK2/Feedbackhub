class ScorecardsController < ApplicationController
  before_action :require_manager_or_admin

  def index
    render Scorecards::IndexComponent.new(tiles: tiles_for(accessible_csr_names))
  end

  def show
    csr = params[:csr].to_s
    unless authorized_for?(csr)
      redirect_to scorecards_path, alert: "That CSR is not on your team." and return
    end

    render Scorecards::ShowComponent.new(
      report: ScorecardReport.new(csr_name: csr, date_range: requested_range)
    )
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

  def tiles_for(names)
    names.map do |name|
      report = ScorecardReport.new(csr_name: name)
      { csr_name: name, count: report.total_count, delta: report.delta }
    end
  end

  def requested_range
    start_date = parse_date(params[:start])
    end_date = parse_date(params[:end])
    return ScorecardReport.default_range unless start_date && end_date
    return ScorecardReport.default_range if start_date > end_date

    start_date.beginning_of_day..end_date.end_of_day
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
