require "rails_helper"

RSpec.describe "API payroll entries", type: :request do
  around { |example| travel_to(Time.zone.local(2026, 10, 15, 9)) { example.run } }

  let(:usa) { create(:country, name: "United States", currency_code: "USD", tax_rate_percent: "25") }

  def hire(name:, salary: 120_000, country: usa, bank: "123456789012")
    employee = create(:employee, name:, country:, joined_on: Date.new(2024, 1, 1), bank_account_number: bank)
    create(:salary_revision, employee:, effective_on: Date.new(2024, 1, 1), amount: salary)
    employee
  end

  def generate(month)
    Payroll::Generator.new(month: Date.parse("#{month}-01")).call.run
  end

  def json
    response.parsed_body
  end

  describe "GET /api/payroll_runs/:month/entries" do
    it "returns 401 when not logged in" do
      get "/api/payroll_runs/2026-10/entries"

      expect(response).to have_http_status(:unauthorized)
    end

    it "lists the month's entries by name with the run's state and totals per currency" do
      create(:exchange_rate, currency_code: "INR", units_per_usd: "83.25")
      india = create(:country, name: "India", currency_code: "INR", tax_rate_percent: "20")
      zoe = hire(name: "Zoe Park", bank: "9876543210")
      hire(name: "Amit Shah", salary: 1_200_000, country: india)
      hire(name: "Bea Cole")
      run = generate("2026-10")
      run.payroll_entries.find_by!(employee: zoe).adjust(bonus: "1000", deduction: "10000", note: "Advance")
      log_in(create(:user))

      get "/api/payroll_runs/2026-10/entries"

      expect(response).to have_http_status(:ok)
      expect(json["payroll_run"]).to eq(
        "month" => "2026-10", "open" => true, "outdated" => false, "calculated_at" => "2026-10-15T09:00:00.000Z",
        "totals" => [
          { "currency_code" => "INR", "entries" => 1, "monthly_gross" => "100000.00", "bonus" => "0.00",
            "deduction" => "0.00", "tax" => "20000.00", "net" => "80000.00" },
          { "currency_code" => "USD", "entries" => 2, "monthly_gross" => "20000.00", "bonus" => "1000.00",
            "deduction" => "10000.00", "tax" => "5250.00", "net" => "5750.00" }
        ]
      )
      expect(json["total"]).to eq(3)
      expect(json["entries"].map { |e| e["name"] }).to eq([ "Amit Shah", "Bea Cole", "Zoe Park" ])
      expect(json["entries"].last).to eq(
        "id" => run.payroll_entries.find_by!(employee: zoe).id, "employee_id" => zoe.id, "code" => zoe.code,
        "name" => "Zoe Park", "country" => "United States", "currency_code" => "USD", "days_worked" => 31,
        "days_in_month" => 31, "annual_salary" => "120000.00", "monthly_gross" => "10000.00", "bonus" => "1000.00",
        "deduction" => "10000.00", "note" => "Advance", "tax_rate_percent" => "25.00", "tax" => "2750.00",
        "net" => "-1750.00", "negative_net" => true, "bank_account" => "••••3210"
      )
      expect(response.body).not_to include("9876543210")
    end

    it "searches by name or code and pages by 25" do
      26.times { |i| hire(name: format("Person %02d", i + 1)) }
      nair = hire(name: "Priya Nair")
      generate("2026-10")
      log_in(create(:user))

      get "/api/payroll_runs/2026-10/entries", params: { page: 2 }
      expect(json["entries"].map { |e| e["name"] }).to eq([ "Person 26", "Priya Nair" ])
      expect(json["total"]).to eq(27)

      get "/api/payroll_runs/2026-10/entries", params: { q: nair.code.downcase }
      expect(json["entries"].map { |e| e["name"] }).to eq([ "Priya Nair" ])
      expect(json["total"]).to eq(1)
    end

    it "returns 404 for a month without a payroll" do
      log_in(create(:user))

      get "/api/payroll_runs/2026-04/entries"

      expect(response).to have_http_status(:not_found)
    end

    it "runs the same number of queries for 3 or 30 entries" do
      log_in(create(:user))
      3.times { |i| hire(name: "Few #{i}") }
      run = generate("2026-10")
      few = count_queries { get "/api/payroll_runs/2026-10/entries" }
      27.times { |i| hire(name: "More #{i}") }
      Payroll::Generator.new(month: run.month).call

      expect(count_queries { get "/api/payroll_runs/2026-10/entries" }).to eq(few)
    end
  end

  describe "PATCH /api/payroll_runs/:month/entries/:id" do
    let!(:employee) { hire(name: "Priya Nair") }
    let(:entry) { generate("2026-10").payroll_entries.sole }
    let(:path) { "/api/payroll_runs/2026-10/entries/#{entry.id}" }

    it "sets the bonus, deduction and note and returns the recalculated entry" do
      log_in(create(:user))

      patch path, params: { payroll_entry: { bonus: "1000", deduction: "0", note: "Spot award" } }, headers: csrf_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["entry"]).to include("bonus" => "1000.00", "note" => "Spot award", "tax" => "2750.00", "net" => "8250.00",
        "negative_net" => false)
    end

    it "keeps fields that aren't sent" do
      entry.adjust(bonus: "500", deduction: "100", note: nil)
      log_in(create(:user))

      patch path, params: { payroll_entry: { note: "Checked" } }, headers: csrf_headers, as: :json

      expect(entry.reload).to have_attributes(bonus: 500, deduction: 100, note: "Checked")
    end

    it "returns 422 for a locked month or invalid input" do
      log_in(create(:user))
      headers = csrf_headers
      entry

      patch path, params: { payroll_entry: { bonus: "-5" } }, headers:, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to eq("bonus" => [ "must be greater than or equal to 0" ])

      create(:payroll_run, month: Date.new(2026, 11, 1))
      patch path, params: { payroll_entry: { bonus: "5" } }, headers:, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to eq("error" => "This month is locked")
      expect(entry.reload.bonus).to eq(0)
    end

    it "returns 404 for an entry from another month and requires a CSRF token" do
      entry
      other_entry = create(:payroll_entry, payroll_run: create(:payroll_run, month: Date.new(2026, 9, 1)))
      log_in(create(:user))

      patch "/api/payroll_runs/2026-10/entries/#{other_entry.id}", params: { payroll_entry: { bonus: "5" } }, headers: csrf_headers, as: :json
      expect(response).to have_http_status(:not_found)

      patch path, params: { payroll_entry: { bonus: "5" } }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(entry.reload.bonus).to eq(0)
    end
  end
end
