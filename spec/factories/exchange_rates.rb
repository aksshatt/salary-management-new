FactoryBot.define do
  factory :exchange_rate do
    currency_code { "INR" }
    units_per_usd { BigDecimal("83.25") }
  end
end
