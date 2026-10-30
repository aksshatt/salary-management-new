require "rails_helper"

RSpec.describe "API insight trends", type: :request do
  around { |example| travel_to(Date.new(2026, 10, 15)) { example.run } }

  let(:usa) { create(:country, name: "United States", currency_code: "USD") }

  def hire(salary:, joined_on:, **attrs)
    employee = create(:employee, country: usa, joined_on:, **attrs)
    create(:salary_revision, employee:, effective_on: joined_on, amount: salary)
  end

  def json
    response.parsed_body
  end

  it "returns 401 when not logged in" do
    get "/api/insights/trends"

    expect(response).to have_http_status(:unauthorized)
  end

  it "returns 12 monthly points ending last month by default" do
    hire(salary: 12_000, joined_on: Date.new(2026, 9, 3), department: "Sales")
    hire(salary: 24_000, joined_on: Date.new(2026, 9, 3), department: "Engineering")
    log_in(create(:user))

    get "/api/insights/trends", params: { department: "Sales" }

    expect(response).to have_http_status(:ok)
    expect(json["points"].size).to eq(12)
    expect(json["points"].first).to eq("month" => "2025-10", "as_of" => "2025-10-31", "monthly_cost" => nil, "joiners" => 0, "leavers" => 0)
    expect(json["points"].last).to eq("month" => "2026-09", "as_of" => "2026-09-30", "monthly_cost" => "1000.00", "joiners" => 1, "leavers" => 0)
  end

  it "uses the chosen month and returns 422 for a future one" do
    log_in(create(:user))

    get "/api/insights/trends", params: { month: "2026-10" }
    expect(json["points"].last).to include("month" => "2026-10", "as_of" => "2026-10-15")

    get "/api/insights/trends", params: { month: "2026-11" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "runs the same number of queries for 3 or 30 employees" do
    log_in(create(:user))
    3.times { hire(salary: 1_000, joined_on: Date.new(2026, 1, 1)) }
    few = count_queries { get "/api/insights/trends" }
    27.times { hire(salary: 1_000, joined_on: Date.new(2026, 1, 1)) }

    expect(count_queries { get "/api/insights/trends" }).to eq(few)
  end
end
