require "rails_helper"

RSpec.describe Payroll::EntryCalculator do
  def calculate(annual_salary: "120000", days_worked: 30, days_in_month: 30, tax_rate_percent: "25", bonus: "0", deduction: "0")
    described_class.new(
      annual_salary: BigDecimal(annual_salary), days_worked:, days_in_month:, tax_rate_percent: BigDecimal(tax_rate_percent),
      bonus: BigDecimal(bonus), deduction: BigDecimal(deduction)
    ).call
  end

  it "pays a twelfth of the annual salary for a full month, taxed at the country rate" do
    expect(calculate).to eq(monthly_gross: BigDecimal("10000"), tax: BigDecimal("2500"), net: BigDecimal("7500"))
  end

  it "prorates by calendar days worked" do
    expect(calculate(days_worked: 10, days_in_month: 31)).to include(monthly_gross: BigDecimal("3225.81"))
  end

  it "rounds the monthly gross half up at exactly half a cent" do
    expect(calculate(annual_salary: "12000.06", tax_rate_percent: "0")).to include(monthly_gross: BigDecimal("1000.01"))
  end

  it "taxes the bonus with the gross and rounds the tax half up" do
    result = calculate(annual_salary: "12000", tax_rate_percent: "12.5", bonus: "0.04")

    expect(result).to include(monthly_gross: BigDecimal("1000"), tax: BigDecimal("125.01"), net: BigDecimal("875.03"))
  end

  it "takes the deduction after tax, allowing a negative net for loan recovery" do
    result = calculate(annual_salary: "12000", tax_rate_percent: "20", deduction: "1000")

    expect(result).to include(tax: BigDecimal("200"), net: BigDecimal("-200"))
  end
end
