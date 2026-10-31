require "rails_helper"
require "csv"

RSpec.describe Employees::CsvExport do
  around { |example| travel_to(Date.new(2026, 10, 15)) { example.run } }

  let(:india) do
    create(:exchange_rate, currency_code: "INR", units_per_usd: "83.25")
    create(:country, name: "India", currency_code: "INR")
  end

  def export(params = {})
    described_class.new(EmployeeSearch.new(params).results).to_csv
  end

  def rows(csv)
    CSV.parse(csv.delete_prefix("﻿"), headers: true).map(&:to_h)
  end

  it "writes one row per employee with salary in local currency and USD, and a masked bank account" do
    employee = create(:employee, name: "Priya Nair", email: "priya@acme.test", country: india, department: "Sales",
      job_title: "Account Manager", joined_on: Date.new(2024, 1, 15), bank_account_number: "123456789012")
    create(:salary_revision, employee:, effective_on: Date.new(2024, 1, 15), amount: "1320000.50")

    expect(rows(export)).to eq([ {
      "Code" => employee.code, "Name" => "Priya Nair", "Email" => "priya@acme.test", "Country" => "India",
      "Department" => "Sales", "Job title" => "Account Manager", "Joined" => "2024-01-15", "Last working day" => nil,
      "Status" => "active", "Annual salary" => "1320000.50", "Currency" => "INR", "Annual salary (USD)" => "15855.86",
      "Bank account" => "••••9012"
    } ])
  end

  it "starts with a byte-order mark so Excel reads the file as UTF-8" do
    expect(export).to start_with("﻿Code,Name,")
  end

  it "stops text that looks like a formula from running in a spreadsheet, leaving normal text alone" do
    create(:employee, name: "=HYPERLINK(\"http://evil.test\")", department: "+Sales", job_title: "@lead")
    create(:employee, name: "Ana-Maria Costa", department: "R&D", job_title: "Engineer")
    create(:employee, name: "-2+3", department: "\tTab", job_title: "Ops")

    exported = rows(export).to_h { |row| [ row["Email"], row.values_at("Name", "Department", "Job title") ] }.values

    expect(exported).to contain_exactly(
      [ "'=HYPERLINK(\"http://evil.test\")", "'+Sales", "'@lead" ],
      [ "Ana-Maria Costa", "R&D", "Engineer" ],
      [ "'-2+3", "'\tTab", "Ops" ]
    )
  end

  it "escapes commas, quotes and line breaks so the file reads back exactly" do
    create(:employee, name: "O'Brien, \"Pat\"", department: "Sales\nNorth")

    expect(rows(export).first.values_at("Name", "Department")).to eq([ "O'Brien, \"Pat\"", "Sales\nNorth" ])
  end

  it "leaves the salary cells empty when there is no salary or no exchange rate" do
    create(:employee, joined_on: Date.new(2026, 11, 1))
    paid = create(:employee, country: india, joined_on: Date.new(2024, 1, 15))
    create(:salary_revision, employee: paid, effective_on: Date.new(2024, 1, 15), amount: 1000)
    ExchangeRate.where(currency_code: "INR").delete_all

    salaries = rows(export).map { |row| row.values_at("Annual salary", "Currency", "Annual salary (USD)") }

    expect(salaries).to contain_exactly([ nil, nil, nil ], [ "1000.00", "INR", nil ])
  end
end
