FactoryBot.define do
  factory :employee do
    sequence(:name) { |n| "Employee #{n}" }
    sequence(:email) { |n| "employee#{n}@acme.test" }
    country
    department { "Engineering" }
    job_title { "Software Engineer" }
    joined_on { Date.new(2024, 1, 15) }
    bank_account_number { "12345678901234" }
  end
end
