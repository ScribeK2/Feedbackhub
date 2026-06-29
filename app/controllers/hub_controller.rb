class HubController < ApplicationController
  def index
    scope = team_scoped(FeedbackSubmission.all)

    render Dashboard::IndexComponent.new(
      high_count: scope.high_priority.count,
      medium_count: scope.medium_priority.count,
      low_count: scope.low_priority.count,
      total_count: scope.count,
      recent_activity: recent_activity(scope)
    )
  end

  private

  def recent_activity(scope)
    if current_user&.team_scoped?
      scope.includes(:feedback_template).order(created_at: :desc).limit(20).map do |s|
        { type: :feedback, record: s, created_at: s.created_at }
      end
    else
      mixed_recent_activity
    end
  end

  def mixed_recent_activity
    items = []

    FeedbackSubmission.includes(:feedback_template).order(created_at: :desc).limit(20).each do |s|
      items << { type: :feedback, record: s, created_at: s.created_at }
    end

    Article.includes(:author).order(created_at: :desc).limit(20).each do |a|
      items << { type: :article, record: a, created_at: a.created_at }
    end

    Update.includes(:author).order(created_at: :desc).limit(20).each do |u|
      items << { type: :update, record: u, created_at: u.created_at }
    end

    items.sort_by { |i| i[:created_at] }.reverse.first(20)
  end
end
