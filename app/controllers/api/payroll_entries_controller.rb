module Api
  class PayrollEntriesController < BaseController
    include PayrollMonth
    include SalaryJson

    PER_PAGE = 25
    TOTALS = %i[monthly_gross bonus deduction tax net].freeze

    def index
      run = find_run
      entries = run.payroll_entries.joins(:employee).includes(employee: :country).order("employees.name", "employees.id")
      entries = entries.merge(Employee.search(params[:q])) if params[:q].present?
      page = [ params[:page].to_i, 1 ].max

      render json: {
        payroll_run: run_json(run),
        entries: entries.limit(PER_PAGE).offset((page - 1) * PER_PAGE).map { |entry| entry_json(entry) },
        total: entries.count,
        page:,
        per_page: PER_PAGE
      }
    end

    def update
      run = find_run
      entry = run.payroll_entries.find(params[:id])
      return render(json: { error: "This month is locked" }, status: :unprocessable_content) unless run.open?

      if entry.adjust(**params.expect(payroll_entry: %i[bonus deduction note]).to_h.symbolize_keys)
        render json: { entry: entry_json(entry) }
      else
        render json: { errors: entry.errors.to_hash }, status: :unprocessable_content
      end
    end

    private
      def find_run
        PayrollRun.find_by!(month: parse_month(params[:payroll_run_month]))
      end

      def run_json(run)
        {
          month: run.month.strftime("%Y-%m"), open: run.open?, outdated: run.outdated?, calculated_at: run.calculated_at,
          totals: totals(run)
        }
      end

      # Per currency: amounts in different currencies are never added together.
      def totals(run)
        sums = TOTALS.map { |column| Arel.sql("SUM(#{column})") }
        run.payroll_entries.group(:currency_code).order(:currency_code)
          .pluck(:currency_code, Arel.sql("COUNT(*)"), *sums).map do |currency_code, count, *amounts|
            { currency_code:, entries: count, **TOTALS.zip(amounts.map { |amount| format_money(amount) }).to_h }
          end
      end

      def entry_json(entry)
        employee = entry.employee
        {
          id: entry.id, employee_id: employee.id, code: employee.code, name: employee.name, country: employee.country.name,
          currency_code: entry.currency_code, days_worked: entry.days_worked, days_in_month: entry.days_in_month,
          annual_salary: format_money(entry.annual_salary), monthly_gross: format_money(entry.monthly_gross),
          bonus: format_money(entry.bonus), deduction: format_money(entry.deduction), note: entry.note,
          tax_rate_percent: format_percent(entry.tax_rate_percent), tax: format_money(entry.tax),
          net: format_money(entry.net), negative_net: entry.negative_net?, bank_account: employee.masked_bank_account
        }
      end
  end
end
