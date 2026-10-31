module Api
  # Parses a payroll month given as "YYYY-MM" into the 1st of that month.
  module PayrollMonth
    private
      def parse_month(value)
        Date.strptime(value.to_s, "%Y-%m") if value.to_s.match?(/\A\d{4}-(0[1-9]|1[0-2])\z/)
      end
  end
end
