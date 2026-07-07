# frozen_string_literal: true

module Feedback
  class StatusBadgeComponent < ApplicationComponent
    MODIFIERS = {
      "open" => :info,
      "reviewed" => :warning,
      "actioned" => :success,
      "dismissed" => :ghost
    }.freeze

    def initialize(submission:, size: :sm)
      @submission = submission
      @size = size
    end

    def view_template
      Badge MODIFIERS.fetch(@submission.status, :ghost), @size, class: "badge-soft" do
        plain @submission.status.capitalize
      end
    end
  end
end
