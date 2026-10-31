FactoryBot.define do
  factory :country do
    sequence(:name) { |n| "Country #{n}" }
    currency_code { "USD" }
    tax_rate_percent { BigDecimal("20") }

    # A country's currency must have an exchange rate.
    after(:build) do |country|
      next unless country.currency_code.to_s.match?(/\A[A-Z]{3}\z/)

      ExchangeRate.find_or_create_by!(currency_code: country.currency_code) do |rate|
        rate.units_per_usd = country.currency_code == "USD" ? 1 : 10
      end
    end
  end
end
