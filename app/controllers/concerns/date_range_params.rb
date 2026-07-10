# frozen_string_literal: true

# Shared parsing for ?start=/&end= date params. `date_range_from` returns a
# beginning_of_day..end_of_day range, or nil when either date is missing,
# unparseable, or the range is inverted — callers decide the fallback.
module DateRangeParams
  private

  def date_range_from(start_param, end_param)
    start_date = parse_date(start_param)
    end_date = parse_date(end_param)
    return nil unless start_date && end_date
    return nil if start_date > end_date

    start_date.beginning_of_day..end_date.end_of_day
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
