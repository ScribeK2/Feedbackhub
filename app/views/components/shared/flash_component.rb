module Shared
  class FlashComponent < ApplicationComponent
    def initialize(flash:)
      @flash = flash
    end

    def view_template
      return if @flash.empty?

      div(class: "toast toast-top toast-end z-50") do
        @flash.each do |type, message|
          div(class: "alert #{alert_class(type)}") do
            span { message }
          end
        end
      end
    end

    private

    def alert_class(type)
      case type.to_s
      when "notice", "success"
        "alert-success"
      when "alert", "error"
        "alert-error"
      when "warning"
        "alert-warning"
      else
        "alert-info"
      end
    end
  end
end
