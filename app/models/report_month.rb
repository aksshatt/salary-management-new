# The month a report is for, and the date its figures are "as of": the last
# day of a past month, or today for the current month.
class ReportMonth
  class Invalid < StandardError; end

  attr_reader :as_of

  def self.parse(value)
    raise Invalid, "Month must be YYYY-MM" unless value.to_s.match?(/\A\d{4}-(0[1-9]|1[0-2])\z/)

    first_day = Date.strptime(value, "%Y-%m")
    raise Invalid, "Month can't be in the future" if first_day > Date.current

    new([ first_day.end_of_month, Date.current ].min)
  end

  def self.default
    new(Date.current.prev_month.end_of_month)
  end

  def initialize(as_of)
    @as_of = as_of
  end
end
