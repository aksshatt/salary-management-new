# Month-by-month figures for the 12 months ending with a report month.
class SalaryTrendsQuery
  def initialize(as_of:, country_id: nil, department: nil, job_title: nil)
    @binds = { as_of:, country_id: country_id.presence, department: department.presence, job_title: job_title.presence }
  end

  def points
    select_all(<<~SQL).map { |row| row.symbolize_keys.merge(month: row["month_start"].strftime("%Y-%m")).except(:month_start) }
      SELECT months.month_start, months.as_of, cost.monthly_cost, moves.joiners, moves.leavers
      FROM (
        SELECT month_start::date AS month_start,
          LEAST((month_start + INTERVAL '1 month - 1 day')::date, :as_of) AS as_of
        FROM generate_series(date_trunc('month', CAST(:as_of AS date)) - INTERVAL '11 months',
          date_trunc('month', CAST(:as_of AS date)), INTERVAL '1 month') AS month_start
      ) months
      CROSS JOIN LATERAL (
        SELECT ROUND(SUM(active.usd) / 12, 2) AS monthly_cost
        FROM (#{SalaryStatsQuery.active_salaries_sql("months.as_of")}) active
      ) cost
      CROSS JOIN LATERAL (
        SELECT
          COUNT(*) FILTER (WHERE employees.joined_on BETWEEN months.month_start AND months.as_of) AS joiners,
          COUNT(*) FILTER (WHERE employees.terminated_on BETWEEN months.month_start AND months.as_of) AS leavers
        FROM employees
        WHERE #{SalaryStatsQuery::FILTERS}
      ) moves
      ORDER BY months.month_start
    SQL
  end

  private
    def select_all(sql)
      Employee.connection.select_all(Employee.sanitize_sql([ sql.squish, @binds ])).to_a
    end
end
