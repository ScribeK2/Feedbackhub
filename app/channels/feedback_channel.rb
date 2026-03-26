class FeedbackChannel < ApplicationCable::Channel
  def subscribed
    stream_from "feedback_submissions"
  end

  def unsubscribed
  end
end
