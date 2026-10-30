module Api
  class EmployeesController < BaseController
    include SalaryJson

    PER_PAGE = 25

    def index
      employees = EmployeeSearch.new(params).results
      page = [ params[:page].to_i, 1 ].max
      paged = employees.limit(PER_PAGE).offset((page - 1) * PER_PAGE)

      render json: {
        employees: paged.map { |employee| employee_json(employee).merge(current_salary: current_salary_json(employee)) },
        total: employees.unscope(:select).count,
        page: page,
        per_page: PER_PAGE
      }
    end

    def show
      employee = Employee.includes(:country).find(params[:id])
      current = employee.current_revision
      revisions = employee.salary_revisions.order(effective_on: :desc)

      render json: {
        employee: employee_json(employee).merge(
          current_salary: current && money_json(current.amount, current.currency_code),
          salary_revisions: revisions.map { |revision| revision_json(revision) }
        )
      }
    end

    def create
      result = Employees::Create.new(employee_params, initial_salary: params[:initial_salary]).call

      if result.success?
        render json: { employee: employee_json(result.employee) }, status: :created
      else
        render json: { errors: result.errors }, status: :unprocessable_content
      end
    end

    def update
      employee = Employee.find(params[:id])

      if employee.update(employee_params)
        render json: { employee: employee_json(employee) }
      else
        render json: { errors: employee.errors.to_hash }, status: :unprocessable_content
      end
    end

    private
      def employee_params
        params.expect(employee: %i[name email country_id department job_title joined_on bank_account_number])
      end

      def current_salary_json(employee)
        employee.current_salary_amount && money_json(employee.current_salary_amount, employee.current_salary_currency)
      end

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
