module Api
  class ExchangeRatesController < BaseController
    def index
      countries = Country.order(:name).group_by(&:currency_code)

      render json: {
        exchange_rates: ExchangeRate.order(:currency_code).map { |rate| rate_json(rate, countries) }
      }
    end

    def update
      rate = ExchangeRate.find_by!(currency_code: params[:currency_code])

      if rate.update(params.expect(exchange_rate: [ :units_per_usd ]))
        render json: { exchange_rate: rate_json(rate, Country.order(:name).group_by(&:currency_code)) }
      else
        render json: { errors: rate.errors.to_hash }, status: :unprocessable_content
      end
    end

    private
      # The rate goes out as an exact decimal string, never a float.
      def rate_json(rate, countries)
        {
          currency_code: rate.currency_code,
          units_per_usd: rate.units_per_usd.to_s("F"),
          countries: countries.fetch(rate.currency_code, []).map(&:name)
        }
      end
  end
end
