module Api
  class InsightsController < BaseController
    include SalaryJson

    MONEY = %i[annual_cost monthly_cost average median lowest highest].freeze

    rescue_from ReportMonth::Invalid do |error|
      render json: { error: error.message }, status: :unprocessable_content
    end

    def show
      month = report_month
      query = SalaryStatsQuery.new(as_of: month.as_of, **filters)
      group_by = params[:group_by] == "department" ? :department : :country

      render json: {
        month: month.as_of.strftime("%Y-%m"),
        as_of: month.as_of,
        stats: money_values(query.stats),
        breakdown: { group_by:, groups: query.breakdown(group_by).map { |group| money_values(group) } }
      }
    end

    def trends
      points = SalaryTrendsQuery.new(as_of: report_month.as_of, **filters).points

      render json: { points: points.map { |point| money_values(point) } }
    end

    private
      def report_month
        params[:month].present? ? ReportMonth.parse(params[:month]) : ReportMonth.default
      end

      def filters
        params.permit(:country_id, :department, :job_title).to_h.symbolize_keys
      end

      def money_values(row)
        row.to_h do |key, value|
          if value.nil? then [ key, nil ]
          elsif key.in?(MONEY) then [ key, format_money(value) ]
          elsif key == :average_raise_percent then [ key, format_percent(value) ]
          else [ key, value ]
          end
        end
      end
  end
end
