# Month-by-month figures for the 12 months ending with a report month.
class SalaryTrendsQuery
  # Each revision's % change (computed over the full history, so the first
  # raise in the window still compares with the revision before it) from the employee's previous one by date, rounded
  # half up to 2 decimals; NULL for the first one and after a currency change.
  # The same rule as SalaryRevision.change_percents.
  REVISION_CHANGES = <<~SQL.squish
    SELECT salary_revisions.*,
      CASE WHEN LAG(currency_code) OVER history = currency_code
        THEN ROUND((amount - LAG(amount) OVER history) / LAG(amount) OVER history * 100, 2)
      END AS change_percent
    FROM salary_revisions
    WINDOW history AS (PARTITION BY employee_id ORDER BY effective_on)
  SQL

  def initialize(as_of:, country_id: nil, department: nil, job_title: nil)
    @binds = { as_of:, country_id: country_id.presence, department: department.presence, job_title: job_title.presence }
  end

  def points
    select_all(<<~SQL).map { |row| row.symbolize_keys.merge(month: row["month_start"].strftime("%Y-%m")).except(:month_start) }
      WITH changes AS MATERIALIZED (
        SELECT * FROM (#{REVISION_CHANGES}) all_changes
        WHERE reason IN ('increment', 'promotion') AND change_percent IS NOT NULL
          AND effective_on BETWEEN date_trunc('month', CAST(:as_of AS date)) - INTERVAL '11 months' AND :as_of
      )
      SELECT months.month_start, months.as_of, cost.monthly_cost, moves.joiners, moves.leavers,
        raises.raises, raises.average_raise_percent
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
      CROSS JOIN LATERAL (
        SELECT COUNT(*) AS raises, ROUND(AVG(changes.change_percent), 2) AS average_raise_percent
        FROM changes
        JOIN employees ON employees.id = changes.employee_id
        WHERE changes.effective_on BETWEEN months.month_start AND months.as_of
          AND (employees.terminated_on IS NULL OR changes.effective_on <= employees.terminated_on)
          AND #{SalaryStatsQuery::FILTERS}
      ) raises
      ORDER BY months.month_start
    SQL
  end

  private
    def select_all(sql)
      Employee.connection.select_all(Employee.sanitize_sql([ sql.squish, @binds ])).to_a
    end
end
