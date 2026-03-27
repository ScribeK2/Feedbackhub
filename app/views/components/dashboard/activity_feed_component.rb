# frozen_string_literal: true

module Dashboard
  class ActivityFeedComponent < ApplicationComponent
    def initialize(items:)
      @items = items
    end

    def view_template
      Card class: "glass-card" do |card|
        card.body do
          h2(class: "card-title text-lg font-bold mb-4") { "Recent Activity" }
          if @items.empty?
            p(class: "text-base-content/60 text-center py-4") { "No recent activity." }
          else
            div(id: "recent_activity", class: "space-y-3") do
              @items.each do |item|
                render ActivityItemComponent.new(item: item[:record], type: item[:type])
              end
            end
          end
        end
      end
    end
  end
end
