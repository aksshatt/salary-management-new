FactoryBot.define do
  factory :payroll_run do
    month { Date.new(2026, 9, 1) }
    calculated_at { Time.current }
  end
end
