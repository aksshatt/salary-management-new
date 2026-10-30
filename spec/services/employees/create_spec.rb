require "rails_helper"

RSpec.describe Employees::Create do
  let(:india) { create(:country, name: "India", currency_code: "INR") }
  let(:attributes) do
    {
      name: "Priya Nair", email: "priya@acme.test", country_id: india.id, department: "Sales",
      job_title: "Account Manager", joined_on: "2026-11-02", bank_account_number: "123456789012"
    }
  end

  it "creates the employee with an initial salary dated on the join date" do
    result = described_class.new(attributes, initial_salary: "1200000").call

    expect(result).to be_success
    expect(result.employee).to have_attributes(name: "Priya Nair", joined_on: Date.new(2026, 11, 2))
    expect(result.employee.salary_revisions.map { |r| [ r.effective_on, r.amount, r.currency_code, r.reason ] })
      .to eq([ [ Date.new(2026, 11, 2), BigDecimal("1200000"), "INR", "initial" ] ])
  end

  it "saves nothing and reports the salary error when the initial salary is invalid" do
    result = described_class.new(attributes, initial_salary: "0").call

    expect(result).not_to be_success
    expect(result.errors).to eq(initial_salary: [ "must be greater than 0" ])
    expect(Employee.count).to eq(0)
  end

  it "reports employee and salary errors together and saves nothing" do
    create(:employee, email: "priya@acme.test")

    result = described_class.new(attributes.merge(name: ""), initial_salary: "-1").call

    expect(result).not_to be_success
    expect(result.errors).to eq(
      name: [ "can't be blank" ],
      email: [ "has already been taken" ],
      initial_salary: [ "must be greater than 0" ]
    )
    expect(Employee.count).to eq(1)
    expect(SalaryRevision.count).to eq(0)
  end
end
