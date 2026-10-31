# Search, filters and sort order for the employee list.
class EmployeeSearch
  STATUSES = %w[active upcoming terminated].freeze

  def initialize(params)
    @params = params
  end

  # The salary in effect today, or on the last working day for someone who
  # left, joined in one query (same rule as Employee#current_revision), with its
  # USD value. Postgres ROUND on numeric rounds half up, like ExchangeRate.to_usd.
  CURRENT_SALARY_JOIN = <<~SQL.squish
    LEFT JOIN LATERAL (
      SELECT salary_revisions.amount, salary_revisions.currency_code,
        ROUND(salary_revisions.amount / exchange_rates.units_per_usd, 2) AS usd
      FROM salary_revisions
      LEFT JOIN exchange_rates ON exchange_rates.currency_code = salary_revisions.currency_code
      WHERE salary_revisions.employee_id = employees.id
        AND salary_revisions.effective_on <= LEAST(:today, COALESCE(employees.terminated_on, :today))
      ORDER BY salary_revisions.effective_on DESC
      LIMIT 1
    ) current_salary ON true
  SQL

  def results
    employees = Employee.includes(:country).order(:name, :id)
      .joins(Employee.sanitize_sql([ CURRENT_SALARY_JOIN, { today: Date.current } ]))
      .select("employees.*, current_salary.amount AS current_salary_amount, current_salary.currency_code AS current_salary_currency, " \
        "current_salary.usd AS current_salary_usd")
    employees = employees.search(@params[:q]) if @params[:q].present?
    employees = employees.where(country_id: @params[:country_id]) if @params[:country_id].present?
    employees = employees.where(department: @params[:department]) if @params[:department].present?
    employees = employees.where(job_title: @params[:job_title]) if @params[:job_title].present?
    employees = employees.public_send(@params[:status]) if @params[:status].in?(STATUSES)
    employees
  end
end
