require "rails_helper"

RSpec.describe "API payroll export", type: :request do
  around { |example| travel_to(Date.new(2026, 10, 15)) { example.run } }

  before do
    employee = create(:employee, joined_on: Date.new(2024, 1, 1), bank_account_number: "DE89370400440532013000")
    create(:salary_revision, employee:, effective_on: Date.new(2024, 1, 1))
    Payroll::Generator.new(month: Date.new(2026, 9, 1)).call
  end

  it "returns 401 when not logged in" do
    get "/api/payroll_runs/2026-09/export.xlsx"

    expect(response).to have_http_status(:unauthorized)
  end

  it "downloads the month as an Excel file with full bank account numbers" do
    log_in(create(:user))

    get "/api/payroll_runs/2026-09/export.xlsx"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    expect(response.headers["Content-Disposition"]).to include('attachment; filename="payroll-2026-09.xlsx"')
    expect(read_xlsx(response.body)[1][2]).to eq([ "DE89370400440532013000", :string ])
  end

  it "returns 404 for a month without a payroll" do
    log_in(create(:user))

    get "/api/payroll_runs/2026-08/export.xlsx"

    expect(response).to have_http_status(:not_found)
  end
end
