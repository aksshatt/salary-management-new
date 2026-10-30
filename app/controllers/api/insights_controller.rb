module Api
  class InsightsController < BaseController
    include SalaryJson

    MONEY = %i[annual_cost monthly_cost average median lowest highest].freeze

    rescue_from ReportMonth::Invalid do |error|
      render json: { error: error.message }, status: :unprocessable_content
    end

    def show
      month = params[:month].present? ? ReportMonth.parse(params[:month]) : ReportMonth.default
      query = SalaryStatsQuery.new(as_of: month.as_of, **params.permit(:country_id, :department, :job_title).to_h.symbolize_keys)
      group_by = params[:group_by] == "department" ? :department : :country

      render json: {
        month: month.as_of.strftime("%Y-%m"),
        as_of: month.as_of,
        stats: money_values(query.stats),
        breakdown: { group_by:, groups: query.breakdown(group_by).map { |group| money_values(group) } }
      }
    end

    private
      def money_values(row)
        row.to_h { |key, value| [ key, key.in?(MONEY) && value ? format_money(value) : value ] }
      end
  end
end
