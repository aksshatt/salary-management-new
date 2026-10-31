module Payroll
  # One employee's pay for one month, in their local currency (BigDecimal only):
  #   monthly gross = annual / 12 × days worked / days in month   (rounded half up)
  #   taxable       = monthly gross + bonus
  #   tax           = rate % × taxable                           (rounded half up)
  #   net           = taxable − tax − deduction                  (may be negative)
  class EntryCalculator
    def initialize(annual_salary:, days_worked:, days_in_month:, tax_rate_percent:, bonus:, deduction:)
      @annual_salary = annual_salary
      @days_worked = days_worked
      @days_in_month = days_in_month
      @tax_rate_percent = tax_rate_percent
      @bonus = bonus
      @deduction = deduction
    end

    def call
      monthly_gross = (@annual_salary / 12 * @days_worked / @days_in_month).round(2, BigDecimal::ROUND_HALF_UP)
      taxable = monthly_gross + @bonus
      tax = (@tax_rate_percent / 100 * taxable).round(2, BigDecimal::ROUND_HALF_UP)
      { monthly_gross:, tax:, net: taxable - tax - @deduction }
    end
  end
end
