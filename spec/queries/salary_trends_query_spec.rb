require "rails_helper"

RSpec.describe SalaryTrendsQuery do
  around { |example| travel_to(Date.new(2026, 10, 15)) { example.run } }

  let(:usa) { create(:country, name: "United States", currency_code: "USD") }

  def hire(salary:, joined_on: Date.new(2024, 1, 1), terminated_on: nil, **attrs)
    employee = create(:employee, country: usa, joined_on:, terminated_on:, **attrs)
    create(:salary_revision, employee:, effective_on: joined_on, amount: salary)
    employee
  end

  def points(month, **filters)
    described_class.new(as_of: Date.parse(month), **filters).points
  end

  it "covers the 12 months ending with the chosen one, oldest first, across the new year" do
    result = points("2026-01-31")

    expect(result.map { |point| point[:month] }).to eq(%w[2025-02 2025-03 2025-04 2025-05 2025-06 2025-07 2025-08 2025-09 2025-10 2025-11 2025-12 2026-01])
    expect(result.first[:as_of]).to eq(Date.new(2025, 2, 28))
  end

  it "reports each month's salary cost, picking up a raise from the month it starts" do
    employee = hire(salary: 120_000)
    create(:salary_revision, employee:, effective_on: Date.new(2026, 5, 1), amount: 132_000, reason: "increment")
    hire(salary: 60_001)

    costs = points("2026-09-30").to_h { |point| [ point[:month], point[:monthly_cost] ] }

    expect(costs.values_at("2026-04", "2026-05", "2026-09")).to eq([ BigDecimal("15000.08"), BigDecimal("16000.08"), BigDecimal("16000.08") ])
    expect(costs["2026-09"]).to eq(SalaryStatsQuery.new(as_of: Date.new(2026, 9, 30)).stats[:monthly_cost])
  end

  it "counts joiners and leavers by the month of their join date and last working day" do
    hire(salary: 1, joined_on: Date.new(2026, 8, 1))
    hire(salary: 1, joined_on: Date.new(2026, 8, 31))
    hire(salary: 1, joined_on: Date.new(2026, 9, 1))
    hire(salary: 1, terminated_on: Date.new(2026, 8, 31))
    hire(salary: 1, joined_on: Date.new(2026, 10, 15))
    hire(salary: 1, joined_on: Date.new(2026, 10, 16))
    hire(salary: 1, terminated_on: Date.new(2026, 10, 30))

    counts = points("2026-10-15").to_h { |point| [ point[:month], [ point[:joiners], point[:leavers] ] ] }

    expect(counts.values_at("2026-08", "2026-09", "2026-10", "2026-07")).to eq([ [ 2, 1 ], [ 1, 0 ], [ 1, 0 ], [ 0, 0 ] ])
  end

  it "applies the filters to the cost and to joiners and leavers" do
    hire(salary: 12_000, joined_on: Date.new(2026, 9, 1), department: "Sales")
    hire(salary: 24_000, joined_on: Date.new(2026, 9, 1), department: "Engineering")

    september = points("2026-09-30", department: "Sales").last

    expect(september).to include(monthly_cost: BigDecimal("1000"), joiners: 1, leavers: 0)
  end

  it "has no cost and zero joiners and leavers in months with nobody" do
    expect(points("2026-09-30").first).to eq(month: "2025-10", as_of: Date.new(2025, 10, 31), monthly_cost: nil, joiners: 0, leavers: 0)
  end

  it "ends February on the 29th in a leap year" do
    hire(salary: 12_000, joined_on: Date.new(2024, 2, 29))

    february = points("2024-02-29").last

    expect(february).to include(month: "2024-02", as_of: Date.new(2024, 2, 29), monthly_cost: BigDecimal("1000"), joiners: 1)
  end
end
