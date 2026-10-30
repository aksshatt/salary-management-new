module Api
  class EmployeesController < BaseController
    PER_PAGE = 25

    def index
      employees = EmployeeSearch.new(params).results
      page = [ params[:page].to_i, 1 ].max
      paged = employees.limit(PER_PAGE).offset((page - 1) * PER_PAGE)

      render json: {
        employees: paged.map { |employee| employee_json(employee) },
        total: employees.count,
        page: page,
        per_page: PER_PAGE
      }
    end

    private
      def employee_json(employee)
        {
          id: employee.id,
          code: employee.code,
          name: employee.name,
          email: employee.email,
          country: employee.country.slice(:id, :name, :currency_code),
          department: employee.department,
          job_title: employee.job_title,
          joined_on: employee.joined_on,
          terminated_on: employee.terminated_on,
          status: employee.status,
          bank_account: employee.masked_bank_account
        }
      end
  end
end
