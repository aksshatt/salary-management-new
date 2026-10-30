FactoryBot.define do
  factory :salary_revision do
    employee
    amount { BigDecimal("1200000.00") }
    effective_on { employee.joined_on }
    reason { "initial" }
  end
end
