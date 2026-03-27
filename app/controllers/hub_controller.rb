class HubController < ApplicationController
  def index
    @high_count = FeedbackSubmission.high_priority.count
    @medium_count = FeedbackSubmission.medium_priority.count
    @low_count = FeedbackSubmission.low_priority.count
    @total_count = FeedbackSubmission.count

    render Dashboard::IndexComponent.new(
      high_count: @high_count,
      medium_count: @medium_count,
      low_count: @low_count,
      total_count: @total_count,
      recent_activity: recent_activity
    )
  end

  private

  def recent_activity
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
