require "rails_helper"
require "csv"

RSpec.describe "API employee CSV export", type: :request do
  around { |example| travel_to(Date.new(2026, 10, 15)) { example.run } }

  def exported_rows
    CSV.parse(response.body.delete_prefix("﻿"), headers: true).map(&:to_h)
  end

  it "returns 401 when not logged in" do
    get "/api/employees/export.csv"

    expect(response).to have_http_status(:unauthorized)
  end

  it "downloads every matching employee, across all pages, as a dated CSV file" do
    sales = create_list(:employee, 30, department: "Sales")
    create(:employee, department: "Engineering")
    log_in(create(:user))

    get "/api/employees/export.csv", params: { department: "Sales" }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/csv")
    expect(response.headers["Content-Disposition"]).to include('attachment; filename="employees-2026-10-15.csv"')
    expect(exported_rows.map { |row| row["Code"] }).to match_array(sales.map(&:code))
  end

  it "never includes a full bank account number" do
    create(:employee, bank_account_number: "DE89370400440532013000")
    log_in(create(:user))

    get "/api/employees/export.csv"

    expect(response.body).not_to include("DE89370400440532013000")
    expect(exported_rows.first["Bank account"]).to eq("••••3000")
  end

  it "runs the same number of queries for 3 or 30 employees" do
    log_in(create(:user))
    create_list(:salary_revision, 3)
    few = count_queries { get "/api/employees/export.csv" }
    create_list(:salary_revision, 27)

    expect(count_queries { get "/api/employees/export.csv" }).to eq(few)
  end
end
