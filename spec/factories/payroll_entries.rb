FactoryBot.define do
  factory :payroll_entry do
    payroll_run
    employee
    salary_revision { association :salary_revision, employee:, strategy: :create }
    currency_code { "USD" }
    annual_salary { BigDecimal("120000") }
    tax_rate_percent { BigDecimal("25") }
    days_worked { 30 }
    days_in_month { 30 }
    monthly_gross { BigDecimal("10000") }
    tax { BigDecimal("2500") }
    net { BigDecimal("7500") }
  end
end
