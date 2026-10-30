module Api
  class TerminationsController < BaseController
    include EmployeeJson

    def create
      employee = Employee.includes(:country).find(params[:employee_id])

      if employee.terminate(on: params[:terminated_on])
        render json: { employee: employee_json(employee) }
      else
        render json: { errors: employee.errors.to_hash }, status: :unprocessable_content
      end
    end
  end
end
