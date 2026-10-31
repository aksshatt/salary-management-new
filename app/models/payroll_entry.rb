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
  validates :note, length: { maximum: 500 }

  def negative_net?
    net.negative?
  end

  # HR's one-time bonus, deduction and note. Recalculates only this entry, from
  # the inputs it stored (not current salaries or tax rates).
  def adjust(bonus: self.bonus, deduction: self.deduction, note: self.note)
    assign_attributes(bonus:, deduction:, note:)
    return false unless valid?

    assign_attributes(Payroll::EntryCalculator.new(
      annual_salary:, days_worked:, days_in_month:, tax_rate_percent:, bonus: self.bonus, deduction: self.deduction
    ).call)
    save
  end

  # Entries of a locked month are read-only.
  def readonly?
    persisted? && !payroll_run.open?
  end
end
