require "rails_helper"

RSpec.describe "API insights", type: :request do
  around { |example| travel_to(Date.new(2026, 10, 15)) { example.run } }

  let(:usa) { create(:country, name: "United States", currency_code: "USD") }

  def hire(salary:, joined_on: Date.new(2025, 1, 1), **attrs)
    employee = create(:employee, country: usa, joined_on:, **attrs)
    create(:salary_revision, employee:, effective_on: joined_on, amount: salary)
    employee
  end

  def json
    response.parsed_body
  end

  it "returns 401 when not logged in" do
    get "/api/insights"

    expect(response).to have_http_status(:unauthorized)
  end

  it "defaults to last month and returns the stats and the cost by country" do
    hire(salary: 60_000)
    hire(salary: 90_001)
    hire(salary: 50_000, joined_on: Date.new(2026, 10, 1))
    log_in(create(:user))

    get "/api/insights"

    expect(response).to have_http_status(:ok)
    expect(json).to eq(
      "month" => "2026-09",
      "as_of" => "2026-09-30",
      "stats" => {
        "headcount" => 2, "without_salary" => 0, "annual_cost" => "150001.00", "monthly_cost" => "12500.08",
        "average" => "75000.50", "median" => "75000.50", "lowest" => "60000.00", "highest" => "90001.00"
      },
      "breakdown" => {
        "group_by" => "country",
        "groups" => [ { "name" => "United States", "headcount" => 2, "annual_cost" => "150001.00" } ]
      }
    )
  end

  it "uses the chosen month, as of today for the current month" do
    hire(salary: 50_000, joined_on: Date.new(2026, 10, 1))
    hire(salary: 70_000, joined_on: Date.new(2026, 10, 20))
    log_in(create(:user))

    get "/api/insights", params: { month: "2026-10" }

    expect(json).to include("month" => "2026-10", "as_of" => "2026-10-15")
    expect(json["stats"]["headcount"]).to eq(1)
  end

  it "returns 422 for a future month or one that isn't YYYY-MM" do
    log_in(create(:user))

    get "/api/insights", params: { month: "2026-11" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(json).to eq("error" => "Month can't be in the future")

    get "/api/insights", params: { month: "2026-13" }
    expect(json).to eq("error" => "Month must be YYYY-MM")
  end

  it "applies the filters and breaks the cost down by department when asked" do
    hire(salary: 10_000, department: "Sales", job_title: "Manager")
    hire(salary: 20_000, department: "Engineering", job_title: "Manager")
    hire(salary: 40_000, department: "Engineering", job_title: "Engineer")
    log_in(create(:user))

    get "/api/insights", params: { country_id: usa.id, job_title: "Manager", group_by: "department" }

    expect(json["stats"]).to include("headcount" => 2, "annual_cost" => "30000.00")
    expect(json["breakdown"]).to eq(
      "group_by" => "department",
      "groups" => [
        { "name" => "Engineering", "headcount" => 1, "annual_cost" => "20000.00" },
        { "name" => "Sales", "headcount" => 1, "annual_cost" => "10000.00" }
      ]
    )
  end

  it "runs the same number of queries for 3 or 30 employees" do
    log_in(create(:user))
    3.times { hire(salary: 50_000) }
    few = count_queries { get "/api/insights" }
    27.times { hire(salary: 50_000) }
    many = count_queries { get "/api/insights" }

    expect(many).to eq(few)
  end
end
