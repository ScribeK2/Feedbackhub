# frozen_string_literal: true

module Dashboard
  class MetricCardComponent < ApplicationComponent
    def initialize(title:, count:, modifier: :ghost)
      @title = title
      @count = count
      @modifier = modifier
    end

    def view_template
      Card class: "glass-card" do |card|
        card.body class: "items-center text-center" do
          h2(class: "card-title text-sm font-medium opacity-70") { @title }
          div(class: "text-4xl font-bold mt-2") do
            Badge @modifier, :lg, class: "text-2xl px-4 py-3" do
              plain @count.to_s
            end
          end
        end
      end
    end
  end
end
