module ApplicationHelper
  def priority_badge_class(priority)
    case priority
    when "High" then "badge-error"
    when "Medium" then "badge-warning"
    when "Low" then "badge-success"
    else "badge-ghost"
    end
  end
end
