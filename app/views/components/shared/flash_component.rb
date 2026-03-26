# frozen_string_literal: true

module Shared
  class FlashComponent < ApplicationComponent
    def initialize(flash:)
      @flash = flash
    end

    def view_template
      return if @flash.empty?

      div(class: "toast toast-top toast-end z-50") do
        @flash.each do |type, message|
          Alert alert_modifier(type) do
            span { message }
          end
        end
      end
    end

    private

    def alert_modifier(type)
      case type.to_s
      when "notice", "success" then :success
      when "alert", "error" then :error
      when "warning" then :warning
      else :info
      end
    end
  end
end
