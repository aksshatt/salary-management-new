require "rails_helper"

RSpec.describe "API salary revisions", type: :request do
  let(:india) { create(:country, name: "India", currency_code: "INR") }
  let(:employee) { create(:employee, country: india, joined_on: Date.new(2024, 1, 15)) }
  let(:path) { "/api/employees/#{employee.id}/salary_revisions" }
  let(:valid_params) { { salary_revision: { effective_on: "2025-04-01", amount: "1320000.50", reason: "increment" } } }

  def json
    response.parsed_body
  end

  describe "POST /api/employees/:id/salary_revisions" do
    it "returns 401 when not logged in" do
      post path, params: valid_params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "adds a revision in the employee's currency" do
      log_in(create(:user))

      post path, params: valid_params, headers: csrf_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json["salary_revision"]).to include(
        "effective_on" => "2025-04-01", "amount" => "1320000.50", "currency_code" => "INR", "reason" => "increment"
      )
      expect(employee.salary_revisions.count).to eq(1)
    end

    it "returns 422 with the field errors for an invalid revision" do
      log_in(create(:user))

      post path, params: { salary_revision: { effective_on: "2024-01-14", amount: "0", reason: "increment" } },
        headers: csrf_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to eq(
        "effective_on" => [ "can't be before the join date (2024-01-15)" ],
        "amount" => [ "must be greater than 0" ]
      )
      expect(SalaryRevision.count).to eq(0)
    end

    it "returns 404 for an unknown employee" do
      log_in(create(:user))

      post "/api/employees/0/salary_revisions", params: valid_params, headers: csrf_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
