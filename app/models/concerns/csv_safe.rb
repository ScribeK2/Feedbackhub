# frozen_string_literal: true

# Neutralizes CSV formula injection: a string cell starting with a formula
# trigger char is prefixed with an apostrophe so spreadsheet apps treat it as
# text. Non-string cells pass through so numeric columns stay numeric.
module CsvSafe
  FORMULA_TRIGGERS = /\A[=+\-@\t\r]/

  def csv_safe(value)
    return value unless value.is_a?(String)

    value.match?(FORMULA_TRIGGERS) ? "'#{value}" : value
  end
end
