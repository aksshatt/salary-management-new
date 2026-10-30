# Search, filters and sort order for the employee list.
class EmployeeSearch
  STATUSES = %w[active upcoming terminated].freeze

  def initialize(params)
    @params = params
  end

  def results
    employees = Employee.includes(:country).order(:name, :id)
    employees = search(employees)
    employees = employees.where(country_id: @params[:country_id]) if @params[:country_id].present?
    employees = employees.where(department: @params[:department]) if @params[:department].present?
    employees = employees.where(job_title: @params[:job_title]) if @params[:job_title].present?
    employees = employees.public_send(@params[:status]) if @params[:status].in?(STATUSES)
    employees
  end

  private
    def search(employees)
      return employees if @params[:q].blank?

      pattern = "%#{Employee.sanitize_sql_like(@params[:q].strip)}%"
      employees.where("employees.name ILIKE :q OR employees.code ILIKE :q", q: pattern)
    end
end
