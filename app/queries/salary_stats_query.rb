# Pay statistics in USD for employees active on a given date, computed in SQL.
# Each salary is converted at the current rate and rounded to the cent first,
# so totals match the employee list. Everything stays numeric (no floats).
class SalaryStatsQuery
  GROUPS = { country: "countries.name", department: "employees.department" }.freeze

  # Optional filters as bind parameters; a NULL value means "any".
  FILTERS = <<~SQL.squish
    (CAST(:country_id AS bigint) IS NULL OR employees.country_id = :country_id)
    AND (CAST(:department AS text) IS NULL OR employees.department = :department)
    AND (CAST(:job_title AS text) IS NULL OR employees.job_title = :job_title)
  SQL

  # Active employees on a date, matching the filters, with their salary in USD
  # (NULL when no revision has taken effect or the currency has no rate).
  # `as_of` is a SQL expression, so the trends query can pass a column.
  def self.active_salaries_sql(as_of)
    <<~SQL.squish
      SELECT employees.*, salary.usd
      FROM employees
      LEFT JOIN LATERAL (
        SELECT ROUND(salary_revisions.amount / exchange_rates.units_per_usd, 2) AS usd
        FROM salary_revisions
        JOIN exchange_rates ON exchange_rates.currency_code = salary_revisions.currency_code
        WHERE salary_revisions.employee_id = employees.id AND salary_revisions.effective_on <= #{as_of}
        ORDER BY salary_revisions.effective_on DESC
        LIMIT 1
      ) salary ON true
      WHERE employees.joined_on <= #{as_of} AND (employees.terminated_on IS NULL OR employees.terminated_on >= #{as_of})
        AND #{FILTERS}
    SQL
  end

  ACTIVE_SALARIES = active_salaries_sql(":as_of")

  def initialize(as_of:, country_id: nil, department: nil, job_title: nil)
    @binds = { as_of:, country_id: country_id.presence, department: department.presence, job_title: job_title.presence }
  end

  def stats
    select_all(<<~SQL).first.symbolize_keys
      SELECT
        COUNT(*) AS headcount,
        SUM(usd) AS annual_cost,
        ROUND(SUM(usd) / 12, 2) AS monthly_cost,
        ROUND(AVG(usd), 2) AS average,
        ROUND((PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY usd)
          + PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY usd DESC)) / 2, 2) AS median,
        MIN(usd) AS lowest,
        MAX(usd) AS highest,
        COUNT(*) - COUNT(usd) AS without_salary
      FROM (#{ACTIVE_SALARIES}) active
    SQL
  end

  # Annual cost per country or department, largest first.
  def breakdown(group)
    column = GROUPS.fetch(group)
    select_all(<<~SQL).map(&:symbolize_keys)
      SELECT #{column} AS name, COUNT(*) AS headcount, SUM(employees.usd) AS annual_cost
      FROM (#{ACTIVE_SALARIES}) employees
      JOIN countries ON countries.id = employees.country_id
      GROUP BY #{column}
      ORDER BY annual_cost DESC NULLS LAST, name
    SQL
  end

  private
    def select_all(sql)
      Employee.connection.select_all(Employee.sanitize_sql([ sql.squish, @binds ])).to_a
    end
end
