module Payroll
  # Generates a month's payroll: one entry per employee who worked that month,
  # with the inputs used stored on the entry. Running it again for the open
  # (latest) month recalculates it: amounts are refreshed from current data,
  # HR's bonus, deduction and note are kept, new joiners are added, and no
  # entry is removed.
  class Generator
    Result = Data.define(:run, :error) do
      def success? = error.nil?
    end

    # New months that may be generated now (the open month can always be recalculated).
    def self.generatable_months
      latest = PayrollRun.latest
      this_month = Date.current.beginning_of_month
      candidates = latest ? [ latest.month.next_month ] : [ this_month.prev_month, this_month ]
      candidates.select { |month| new(month:).month_error.nil? }
    end

    def initialize(month:)
      @month = month
      @last_day = month.end_of_month
    end

    def call
      error = month_error
      return Result.new(run: nil, error:) if error

      run = nil
      PayrollRun.transaction do
        run = PayrollRun.find_or_initialize_by(month: @month)
        run.update!(calculated_at: Time.current)
        kept = run.payroll_entries.index_by(&:employee_id)
        rows = eligible_employees.map { |employee| entry_row(run, employee, kept[employee.id]) }
        PayrollEntry.upsert_all(rows, unique_by: %i[payroll_run_id employee_id]) if rows.any?
        run.payroll_entries.reset
      end
      Result.new(run:, error: nil)
    end

    def month_error
      latest = PayrollRun.latest
      this_month = Date.current.beginning_of_month

      if latest.nil?
        allowed = [ this_month.prev_month, this_month ]
        "The first payroll must be for #{allowed.map { |m| label(m) }.join(' or ')}" unless @month.in?(allowed)
      elsif @month < latest.month
        "#{label(@month)} is before the latest payroll and can't be generated"
      elsif @month > latest.month.next_month
        "The next payroll must be for #{label(latest.month.next_month)}"
      elsif @month > this_month
        "The next payroll must be for #{label(@month)}, which hasn't started yet"
      end
    end

    private
      def label(month)
        month.strftime("%Y-%m")
      end

      # Everyone who worked at least one day of the month.
      def eligible_employees
        Employee.includes(:country, :salary_revisions)
          .where(joined_on: ..@last_day)
          .where("terminated_on IS NULL OR terminated_on >= ?", @month)
      end

      # `existing` is the entry from an earlier calculation of this month, if any.
      def entry_row(run, employee, existing)
        first_day_worked = [ employee.joined_on, @month ].max
        last_day_worked = [ employee.terminated_on, @last_day ].compact.min
        days_worked = (last_day_worked - first_day_worked).to_i + 1
        revision = employee.salary_revisions.select { |r| r.effective_on <= last_day_worked }.max_by(&:effective_on)
        rate = employee.country.tax_rate_percent
        days_in_month = @last_day.day
        bonus = existing&.bonus || BigDecimal("0")
        deduction = existing&.deduction || BigDecimal("0")
        amounts = EntryCalculator.new(
          annual_salary: revision.amount, days_worked:, days_in_month:, tax_rate_percent: rate, bonus:, deduction:
        ).call

        {
          payroll_run_id: run.id, employee_id: employee.id, salary_revision_id: revision.id,
          currency_code: revision.currency_code, annual_salary: revision.amount, tax_rate_percent: rate,
          days_worked:, days_in_month:, bonus:, deduction:, note: existing&.note, **amounts,
          created_at: existing&.created_at || Time.current, updated_at: Time.current
        }
      end
  end
end
