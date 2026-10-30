module Api
  class FilterOptionsController < BaseController
    def show
      render json: {
        countries: Country.order(:name).map { |country| country.slice(:id, :name, :currency_code) },
        departments: Employee.distinct.order(:department).pluck(:department),
        job_titles: Employee.distinct.order(:job_title).pluck(:job_title)
      }
    end
  end
end
