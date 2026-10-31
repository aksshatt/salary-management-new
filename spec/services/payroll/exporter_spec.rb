require "rails_helper"

RSpec.describe Payroll::Exporter do
  around { |example| travel_to(Date.new(2026, 10, 15)) { example.run } }

  let(:usa) { create(:country, name: "United States", currency_code: "USD", tax_rate_percent: "25") }

  def hire(name:, salary: 120_000, country: usa, bank: "DE89370400440532013000")
    employee = create(:employee, name:, country:, joined_on: Date.new(2024, 1, 1), bank_account_number: bank)
    create(:salary_revision, employee:, effective_on: Date.new(2024, 1, 1), amount: salary)
    employee
  end

  def export(run)
    read_xlsx(described_class.new(run).to_xlsx)
  end

  it "writes a header and one row per entry with the full bank account and amounts as numbers" do
    priya = hire(name: "Priya Nair")
    run = Payroll::Generator.new(month: Date.new(2026, 9, 1)).call.run
    run.payroll_entries.sole.adjust(bonus: "1000", deduction: "200", note: "Spot award")

    header, row = export(run)

    expect(header.map(&:first)).to eq([ "Code", "Name", "Bank account", "Currency", "Days worked", "Days in month",
      "Annual salary", "Monthly gross", "Bonus", "Deduction", "Note", "Tax rate %", "Tax", "Net" ])
    expect(row).to eq([
      [ priya.code, :string ], [ "Priya Nair", :string ], [ "DE89370400440532013000", :string ], [ "USD", :string ],
      [ 30, :number ], [ 30, :number ], [ 120_000, :number ], [ 10_000, :number ], [ 1000, :number ], [ 200, :number ],
      [ "Spot award", :string ], [ 25, :number ], [ 2750, :number ], [ 8050, :number ]
    ])
  end

  it "keeps text that looks like a formula as plain text" do
    hire(name: "=HYPERLINK(\"http://evil.test\")")
    run = Payroll::Generator.new(month: Date.new(2026, 9, 1)).call.run
    run.payroll_entries.sole.adjust(note: "=1+1")

    row = export(run)[1]

    expect(row.values_at(1, 10)).to eq([ [ "=HYPERLINK(\"http://evil.test\")", :string ], [ "=1+1", :string ] ])
  end

  it "adds a total row per currency below the entries, never mixing currencies" do
    create(:exchange_rate, currency_code: "INR", units_per_usd: "83.25")
    india = create(:country, name: "India", currency_code: "INR", tax_rate_percent: "20")
    hire(name: "Amit", salary: 1_200_000, country: india)
    hire(name: "Bea")
    hire(name: "Cal", salary: 60_000)
    run = Payroll::Generator.new(month: Date.new(2026, 9, 1)).call.run

    rows = export(run)

    expect(rows.map { |row| row[1].first }).to eq([ "Name", "Amit", "Bea", "Cal", nil, "Total INR", "Total USD" ])
    expect(rows.last.values_at(3, 7, 8, 9, 12, 13).map(&:first)).to eq([ "USD", 15_000, 0, 0, 3750, 11_250 ])
  end

  it "shows amounts with thousands separators and 2 decimals" do
    hire(name: "Priya")
    run = Payroll::Generator.new(month: Date.new(2026, 9, 1)).call.run

    styles = nil
    Zip::File.open_buffer(StringIO.new(described_class.new(run).to_xlsx)) { |zip| styles = zip.read("xl/styles.xml") }

    expect(styles).to include('formatCode="#,##0.00"')
  end

  it "reads the stored entries without changing them, also for a locked month" do
    hire(name: "Priya")
    run = Payroll::Generator.new(month: Date.new(2026, 9, 1)).call.run
    Payroll::Generator.new(month: Date.new(2026, 10, 1)).call
    stamps = run.payroll_entries.pluck(:updated_at)

    expect(export(run).size).to eq(4)
    expect(run.payroll_entries.pluck(:updated_at)).to eq(stamps)
  end

  it "keeps digit-only bank account numbers as text, with their leading zeros" do
    hire(name: "Priya", bank: "000123456789")
    run = Payroll::Generator.new(month: Date.new(2026, 9, 1)).call.run

    expect(export(run)[1][2]).to eq([ "000123456789", :string ])
  end
end
