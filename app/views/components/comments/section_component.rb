# frozen_string_literal: true

module Comments
  class SectionComponent < ApplicationComponent
    include Phlex::Rails::Helpers::TurboStreamFrom

    def initialize(submission:, user:)
      @submission = submission
      @user = user
    end

    def view_template
      turbo_frame_tag "comments_submission_#{@submission.id}" do
        turbo_stream_from "feedback_submission_comments:#{@submission.id}"

        div(class: "flex items-center justify-between mb-3") do
          h4(class: "font-semibold text-sm text-base-content/70") do
            plain "Comments"
          end
          render SubscriptionToggleComponent.new(submission: @submission, user: @user)
        end

        div(id: "comments_list_#{@submission.id}", class: "space-y-3 mb-4") do
          @submission.comments.chronological.includes(:author).each do |comment|
            render CommentComponent.new(comment: comment)
          end
        end

        render FormComponent.new(submission: @submission)
      end
    end
  end
end
