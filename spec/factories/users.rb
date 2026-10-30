FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "hr#{n}@acme.test" }
    password { "correct-horse-battery" }
  end
end
