# One month's payroll. `month` is the 1st of that month.
class PayrollRun < ApplicationRecord
  include Auditable

  validates :month, :calculated_at, presence: true
  validates :month, uniqueness: true
  validate :month_starts_on_the_first

  has_many :payroll_entries, dependent: :restrict_with_exception

  def self.latest
    order(:month).last
  end

  # Only the latest month can change; older months are locked as paid.
  def open?
    !self.class.where("month > ?", month).exists?
  end

  # Something payroll uses changed after this run was last calculated, so its
  # numbers may be stale. It can flag a change that doesn't affect them (e.g.
  # a raise dated next year); recalculating is harmless then.
  def outdated?
    SalaryRevision.where("created_at > ?", calculated_at).exists? ||
      Employee.where("updated_at > ?", calculated_at).exists? ||
      Country.where("updated_at > ?", calculated_at).exists?
  end

  private
    def month_starts_on_the_first
      errors.add(:month, "must be the first day of a month") if month && month.day != 1
    end
end
