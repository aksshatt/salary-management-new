module Api
  class PayrollRunsController < BaseController
    include PayrollMonth

    def index
      runs = PayrollRun.left_joins(:payroll_entries).group(:id).order(month: :desc)
        .select("payroll_runs.*, COUNT(payroll_entries.id) AS entries_count")
      latest_month = runs.first&.month

      render json: {
        payroll_runs: runs.map { |run| run_json(run, open: run.month == latest_month) },
        generatable_months: Payroll::Generator.generatable_months.map { |month| month.strftime("%Y-%m") }
      }
    end

    # Generates a new month, or recalculates the open (latest) month.
    def create
      month = parse_month(params[:month]) or return render(json: { error: "Month must be YYYY-MM" }, status: :unprocessable_content)
      existed = PayrollRun.exists?(month:)
      result = Payroll::Generator.new(month:).call
      return render(json: { error: result.error }, status: :unprocessable_content) unless result.success?

      run = result.run
      render json: { payroll_run: run_json(run, open: true, entries_count: run.payroll_entries.count) },
        status: existed ? :ok : :created
    end

    # The month's stored entries as Excel, with full bank account numbers.
    def export
      run = PayrollRun.find_by!(month: parse_month(params[:month]))

      send_data Payroll::Exporter.new(run).to_xlsx,
        type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        filename: "payroll-#{run.month.strftime("%Y-%m")}.xlsx"
    end

    private
      def run_json(run, open:, entries_count: run.entries_count)
        { month: run.month.strftime("%Y-%m"), open:, entries: entries_count, calculated_at: run.calculated_at }
      end
  end
end
