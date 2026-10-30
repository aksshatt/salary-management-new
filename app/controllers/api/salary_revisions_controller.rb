module Api
  class SalaryRevisionsController < BaseController
    include SalaryJson

    def create
      employee = Employee.find(params[:employee_id])
      revision = employee.salary_revisions.new(revision_params)

      if revision.save
        render json: { salary_revision: revision_json(revision) }, status: :created
      else
        render json: { errors: revision.errors.to_hash }, status: :unprocessable_content
      end
    end

    private
      def revision_params
        params.expect(salary_revision: %i[effective_on amount reason])
      end
  end
end
