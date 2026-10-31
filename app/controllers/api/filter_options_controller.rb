module Api
  # Options for the country, department and job title filters. Each list only
  # offers values that have employees matching the *other* chosen filters, so
  # no option leads to an empty result, and a filter never narrows its own
  # list (the user can always switch to another value).
  class FilterOptionsController < BaseController
    def show
      render json: {
        countries: Country.where(id: employees_except(:country_id).select(:country_id)).order(:name)
          .map { |country| country.slice(:id, :name, :currency_code) },
        departments: employees_except(:department).distinct.order(:department).pluck(:department),
        job_titles: employees_except(:job_title).distinct.order(:job_title).pluck(:job_title)
      }
    end

    private
      def employees_except(own)
        filters = params.permit(:country_id, :department, :job_title).to_h.symbolize_keys.except(own).compact_blank
        employees = Employee.where(filters)
        params[:status].in?(EmployeeSearch::STATUSES) ? employees.public_send(params[:status]) : employees
      end
  end
end
