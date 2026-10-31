require "rails_helper"

RSpec.describe "API payroll runs", type: :request do
  around { |example| travel_to(Time.zone.local(2026, 10, 15, 9)) { example.run } }

  let(:usa) { create(:country, name: "United States", currency_code: "USD", tax_rate_percent: "25") }

  def hire
    employee = create(:employee, country: usa, joined_on: Date.new(2024, 1, 1))
    create(:salary_revision, employee:, effective_on: Date.new(2024, 1, 1), amount: 120_000)
  end

  def json
    response.parsed_body
  end

  it "returns 401 when not logged in" do
    get "/api/payroll_runs"

    expect(response).to have_http_status(:unauthorized)
  end

  it "generates the first payroll and lists runs newest first, with only the latest open" do
    2.times { hire }
    log_in(create(:user))
    headers = csrf_headers

    post "/api/payroll_runs", params: { month: "2026-09" }, headers:, as: :json
    expect(response).to have_http_status(:created)
    expect(json["payroll_run"]).to include("month" => "2026-09", "open" => true, "entries" => 2)
    post "/api/payroll_runs", params: { month: "2026-10" }, headers:, as: :json

    get "/api/payroll_runs"

    expect(json["payroll_runs"]).to eq([
      { "month" => "2026-10", "open" => true, "entries" => 2, "calculated_at" => "2026-10-15T09:00:00.000Z" },
      { "month" => "2026-09", "open" => false, "entries" => 2, "calculated_at" => "2026-10-15T09:00:00.000Z" }
    ])
  end

  it "returns 200 when recalculating the open month" do
    hire
    log_in(create(:user))
    headers = csrf_headers
    post "/api/payroll_runs", params: { month: "2026-10" }, headers:, as: :json

    post "/api/payroll_runs", params: { month: "2026-10" }, headers:, as: :json

    expect(response).to have_http_status(:ok)
    expect(PayrollRun.count).to eq(1)
  end

  it "returns 422 with the reason for a month that can't be generated or isn't YYYY-MM" do
    log_in(create(:user))
    headers = csrf_headers

    post "/api/payroll_runs", params: { month: "2026-07" }, headers:, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(json).to eq("error" => "The first payroll must be for 2026-09 or 2026-10")

    post "/api/payroll_runs", params: { month: "Sept" }, headers:, as: :json
    expect(json).to eq("error" => "Month must be YYYY-MM")
  end

  it "requires a CSRF token to generate" do
    log_in(create(:user))

    post "/api/payroll_runs", params: { month: "2026-10" }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(PayrollRun.count).to eq(0)
  end
end
