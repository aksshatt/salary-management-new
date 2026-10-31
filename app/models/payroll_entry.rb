# One employee's pay in one payroll run. It stores the inputs it was
# calculated from, so viewing and exporting never recalculate.
class PayrollEntry < ApplicationRecord
  belongs_to :payroll_run
  belongs_to :employee
  belongs_to :salary_revision

  validates :currency_code, :annual_salary, :tax_rate_percent, :days_worked, :days_in_month, :monthly_gross, :tax, :net,
    presence: true
  validates :employee_id, uniqueness: { scope: :payroll_run_id }
  validates :days_in_month, numericality: { in: 28..31 }, allow_nil: true
  validates :days_worked, numericality: { greater_than_or_equal_to: 1 }, allow_nil: true
  validates :days_worked, numericality: { less_than_or_equal_to: :days_in_month }, if: :days_in_month
  validates :bonus, :deduction, numericality: { greater_than_or_equal_to: 0 }, decimal_places: 2

  # Entries of a locked month are read-only.
  def readonly?
    persisted? && !payroll_run.open?
  end
end
