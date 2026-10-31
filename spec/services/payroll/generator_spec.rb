require "rails_helper"

RSpec.describe Payroll::Generator do
  let(:today) { Date.new(2026, 10, 15) }

  around { |example| travel_to(today) { example.run } }

  let(:usa) { create(:country, name: "United States", currency_code: "USD", tax_rate_percent: "25") }

  def hire(salary: "120000", joined_on: Date.new(2024, 1, 1), terminated_on: nil, country: usa)
    employee = create(:employee, country:, joined_on:, terminated_on:)
    create(:salary_revision, employee:, effective_on: joined_on, amount: salary)
    employee
  end

  def generate(month)
    described_class.new(month: Date.parse(month)).call
  end

  it "creates the first run with one entry per employee, stored with the inputs it used" do
    employee = hire

    result = generate("2026-09-01")

    expect(result).to be_success
    expect(result.run).to have_attributes(month: Date.new(2026, 9, 1), calculated_at: Time.current)
    expect(result.run.payroll_entries.sole).to have_attributes(
      employee:, salary_revision: employee.salary_revisions.sole, currency_code: "USD", annual_salary: 120_000,
      tax_rate_percent: 25, days_worked: 30, days_in_month: 30, monthly_gross: 10_000, bonus: 0, deduction: 0,
      tax: 2_500, net: 7_500
    )
  end

  it "includes everyone who worked at least one day, prorated by the days they worked" do
    joins_first = hire(joined_on: Date.new(2026, 9, 1))
    joins_mid = hire(joined_on: Date.new(2026, 9, 21))
    joins_last = hire(joined_on: Date.new(2026, 9, 30))
    leaves_first = hire(terminated_on: Date.new(2026, 9, 1))
    leaves_mid = hire(terminated_on: Date.new(2026, 9, 10))
    hire(terminated_on: Date.new(2026, 8, 31))
    hire(joined_on: Date.new(2026, 10, 1))

    entries = generate("2026-09-01").run.payroll_entries.to_h { |entry| [ entry.employee, entry ] }

    expect(entries.transform_values(&:days_worked)).to eq(
      joins_first => 30, joins_mid => 10, joins_last => 1, leaves_first => 1, leaves_mid => 10
    )
    expect(entries[joins_mid].monthly_gross).to eq(BigDecimal("3333.33"))
  end

  it "uses the salary in effect on each employee's last day worked that month" do
    stays = hire(salary: "120000")
    raise_mid = create(:salary_revision, employee: stays, effective_on: Date.new(2026, 9, 16), amount: "132000", reason: "increment")
    leaves = hire(salary: "120000")
    create(:salary_revision, employee: leaves, effective_on: Date.new(2026, 9, 25), amount: "144000", reason: "increment")
    leaves.terminate(on: Date.new(2026, 9, 20))

    entries = generate("2026-09-01").run.payroll_entries.to_h { |entry| [ entry.employee, entry ] }

    expect(entries[stays]).to have_attributes(salary_revision: raise_mid, annual_salary: 132_000, monthly_gross: 11_000)
    expect(entries[leaves]).to have_attributes(annual_salary: 120_000, days_worked: 20, monthly_gross: BigDecimal("6666.67"))
  end

  describe "which month can be generated" do
    it "starts with the current or the previous month only" do
      expect(generate("2026-08-01").error).to eq("The first payroll must be for 2026-09 or 2026-10")
      expect(generate("2026-11-01").error).to eq("The first payroll must be for 2026-09 or 2026-10")
      expect(PayrollRun.count).to eq(0)
      expect(generate("2026-10-01")).to be_success
    end

    it "then only the month right after the latest, never skipping one or going into the future" do
      generate("2026-09-01")

      expect(generate("2026-11-01").error).to eq("The next payroll must be for 2026-10")
      expect(generate("2026-10-01")).to be_success
      expect(generate("2026-11-01").error).to eq("The next payroll must be for 2026-11, which hasn't started yet")
      expect(generate("2026-08-01").error).to eq("2026-08 is before the latest payroll and can't be generated")
    end
  end

  describe "recalculating the open month" do
    it "refreshes the amounts from current data, keeping HR's bonus, deduction and note, and adds new joiners" do
      employee = hire(salary: "120000")
      first = generate("2026-10-01").run
      entry = first.payroll_entries.sole
      entry.update!(bonus: 1000, deduction: 500, note: "Loan repayment")
      create(:salary_revision, employee:, effective_on: Date.new(2026, 10, 1), amount: "132000", reason: "increment")
      usa.update!(tax_rate_percent: 20)
      newcomer = hire(joined_on: Date.new(2026, 10, 12))
      first.update_column(:calculated_at, 1.day.ago)

      result = generate("2026-10-01")

      expect(result).to be_success
      expect(result.run).to eq(first)
      expect(result.run.reload.calculated_at).to eq(Time.current)
      expect(entry.reload).to have_attributes(
        annual_salary: 132_000, tax_rate_percent: 20, monthly_gross: 11_000, bonus: 1000, deduction: 500,
        note: "Loan repayment", tax: 2_400, net: 9_100
      )
      expect(result.run.payroll_entries.map(&:employee)).to contain_exactly(employee, newcomer)
    end
  end

  it "never removes an entry on recalculation, even if the employee no longer qualifies" do
    employee = hire
    run = generate("2026-10-01").run
    employee.update_column(:terminated_on, Date.new(2026, 9, 30))

    generate("2026-10-01")

    expect(run.payroll_entries.reload.map(&:employee)).to eq([ employee ])
  end

  it "pays each employee in their country's currency and tax rate" do
    create(:exchange_rate, currency_code: "INR", units_per_usd: "83.25")
    india = create(:country, name: "India", currency_code: "INR", tax_rate_percent: "20")
    indian = hire(salary: "1200000", country: india)

    entry = generate("2026-09-01").run.payroll_entries.find_by!(employee: indian)

    expect(entry).to have_attributes(currency_code: "INR", tax_rate_percent: 20, monthly_gross: 100_000, tax: 20_000, net: 80_000)
  end

  context "in a leap year" do
    let(:today) { Date.new(2024, 3, 10) }

    it "counts 29 days in February" do
      hire(joined_on: Date.new(2023, 1, 1))
      late_joiner = hire(joined_on: Date.new(2024, 2, 20))

      entries = generate("2024-02-01").run.payroll_entries.to_h { |entry| [ entry.employee, entry ] }

      expect(entries.values.map(&:days_in_month).uniq).to eq([ 29 ])
      expect(entries[late_joiner].days_worked).to eq(10)
    end
  end
end
