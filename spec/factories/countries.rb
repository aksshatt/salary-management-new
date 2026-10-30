FactoryBot.define do
  factory :country do
    sequence(:name) { |n| "Country #{n}" }
    currency_code { "USD" }
  end
end
