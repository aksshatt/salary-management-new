module Api
  class CountriesController < BaseController
    include SalaryJson

    def index
      render json: { countries: Country.order(:name).map { |country| country_json(country) } }
    end

    # Only the tax rate can be changed here.
    def update
      country = Country.find(params[:id])

      if country.update(params.expect(country: [ :tax_rate_percent ]))
        render json: { country: country_json(country) }
      else
        render json: { errors: country.errors.to_hash }, status: :unprocessable_content
      end
    end

    private
      def country_json(country)
        country.slice(:id, :name, :currency_code).merge(tax_rate_percent: format_percent(country.tax_rate_percent))
      end
  end
end
