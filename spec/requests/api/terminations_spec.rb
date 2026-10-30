require "rails_helper"

RSpec.describe "API termination", type: :request do
  let(:employee) { create(:employee, joined_on: Date.new(2024, 1, 15)) }
  let(:path) { "/api/employees/#{employee.id}/termination" }

  def json
    response.parsed_body
  end

  it "returns 401 when not logged in" do
    post path, params: { terminated_on: "2026-10-31" }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it "sets the last working day and returns the employee" do
    log_in(create(:user))

    travel_to(Date.new(2026, 10, 15)) do
      post path, params: { terminated_on: "2026-10-31" }, headers: csrf_headers, as: :json
    end

    expect(response).to have_http_status(:ok)
    expect(json["employee"]).to include("id" => employee.id, "terminated_on" => "2026-10-31", "status" => "active")
    expect(employee.reload.terminated_on).to eq(Date.new(2026, 10, 31))
  end

  it "returns 422 with the error when the date is invalid" do
    log_in(create(:user))

    post path, params: { terminated_on: "2024-01-14" }, headers: csrf_headers, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["errors"]).to eq("terminated_on" => [ "can't be before the join date" ])
  end

  it "returns 422 when the employee is already terminated" do
    employee.terminate(on: Date.new(2025, 6, 30))
    log_in(create(:user))

    post path, params: { terminated_on: "2025-07-31" }, headers: csrf_headers, as: :json

    expect(json["errors"]).to eq("terminated_on" => [ "already terminated" ])
  end

  it "returns 404 for an unknown employee" do
    log_in(create(:user))

    post "/api/employees/0/termination", params: { terminated_on: "2025-07-31" }, headers: csrf_headers, as: :json

    expect(response).to have_http_status(:not_found)
  end

  it "requires a CSRF token" do
    log_in(create(:user))

    post path, params: { terminated_on: "2025-07-31" }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(employee.reload.terminated_on).to be_nil
  end
end
