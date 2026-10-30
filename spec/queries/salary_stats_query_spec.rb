require "rails_helper"

RSpec.describe SalaryStatsQuery do
  let(:as_of) { Date.new(2026, 9, 30) }
  let(:usa) { create(:country, name: "United States", currency_code: "USD") }

  # An employee with one salary from their join date.
  def hire(salary:, country: usa, joined_on: Date.new(2025, 1, 1), terminated_on: nil, **attrs)
    employee = create(:employee, country:, joined_on:, terminated_on:, **attrs)
    create(:salary_revision, employee:, effective_on: joined_on, amount: salary)
    employee
  end

  def stats(**filters)
    described_class.new(as_of:, **filters).stats
  end

  it "counts active employees and adds up their annual salaries" do
    hire(salary: 60_000)
    hire(salary: 90_000)

    expect(stats).to include(headcount: 2, annual_cost: BigDecimal("150000"))
  end

  it "counts people who join or leave on the date, but not the day before or after" do
    hire(salary: 1_000, joined_on: as_of)
    hire(salary: 2_000, joined_on: as_of + 1)
    hire(salary: 4_000, terminated_on: as_of)
    hire(salary: 8_000, terminated_on: as_of - 1)

    expect(stats).to include(headcount: 2, annual_cost: BigDecimal("5000"))
  end

  it "uses the salary in effect on the date, ignoring a raise from the next day" do
    employee = hire(salary: 50_000)
    create(:salary_revision, employee:, effective_on: as_of, amount: 55_000, reason: "increment")
    create(:salary_revision, employee:, effective_on: as_of + 1, amount: 70_000, reason: "increment")

    expect(stats).to include(annual_cost: BigDecimal("55000"))
  end

  it "converts each salary to USD at the current rate, rounding each to the cent" do
    create(:exchange_rate, currency_code: "INR", units_per_usd: "83.25")
    india = create(:country, name: "India", currency_code: "INR")
    hire(salary: "1320000.50", country: india)
    hire(salary: 80_000)

    expect(stats).to include(annual_cost: BigDecimal("95855.86"))
  end

  it "reports monthly cost and the average, median, lowest and highest salary" do
    [ 40_000, 50_000, 70_000, 100_001 ].each { |salary| hire(salary:) }

    expect(stats).to include(
      annual_cost: BigDecimal("260001"),
      monthly_cost: BigDecimal("21666.75"),
      average: BigDecimal("65000.25"),
      median: BigDecimal("60000"),
      lowest: BigDecimal("40000"),
      highest: BigDecimal("100001")
    )
  end

  it "takes the middle salary as the median when the count is odd" do
    [ 40_000, 50_000, 90_000 ].each { |salary| hire(salary:) }

    expect(stats).to include(median: BigDecimal("50000"))
  end

  it "returns a headcount of 0 and no salary figures when nobody matches" do
    expect(stats).to eq(
      headcount: 0, annual_cost: nil, monthly_cost: nil, average: nil, median: nil, lowest: nil, highest: nil,
      without_salary: 0
    )
  end

  it "counts someone whose salary can't be converted, but leaves them out of the salary figures" do
    create(:exchange_rate, currency_code: "INR", units_per_usd: "80")
    hire(salary: 800_000, country: create(:country, name: "India", currency_code: "INR"))
    hire(salary: 60_000)
    ExchangeRate.where(currency_code: "INR").delete_all

    expect(stats).to include(headcount: 2, without_salary: 1, annual_cost: BigDecimal("60000"), average: BigDecimal("60000"))
  end

  it "filters by country" do
    other = create(:country, name: "Other", currency_code: "USD")
    hire(salary: 60_000)
    hire(salary: 90_000, country: other)

    expect(stats(country_id: other.id)).to include(headcount: 1, annual_cost: BigDecimal("90000"))
  end

  it "filters by department and job title, alone or together" do
    hire(salary: 10_000, department: "Sales", job_title: "Manager")
    hire(salary: 20_000, department: "Sales", job_title: "Executive")
    hire(salary: 40_000, department: "Engineering", job_title: "Manager")

    expect([
      stats(department: "Sales")[:annual_cost],
      stats(job_title: "Manager")[:annual_cost],
      stats(department: "Sales", job_title: "Manager")[:annual_cost]
    ]).to eq([ BigDecimal("30000"), BigDecimal("50000"), BigDecimal("10000") ])
  end

  it "breaks the annual cost down by country or department, largest first" do
    other = create(:country, name: "Other", currency_code: "USD")
    hire(salary: 10_000, department: "Sales")
    hire(salary: 30_000, department: "Engineering", country: other)
    hire(salary: 25_000, department: "Engineering")

    query = described_class.new(as_of:)
    expect(query.breakdown(:country)).to eq([
      { name: "United States", headcount: 2, annual_cost: BigDecimal("35000") },
      { name: "Other", headcount: 1, annual_cost: BigDecimal("30000") }
    ])
    expect(query.breakdown(:department).map { |group| group[:name] }).to eq([ "Engineering", "Sales" ])
  end
end
