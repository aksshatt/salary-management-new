require "rails_helper"

RSpec.describe "API exchange rates", type: :request do
  def json
    response.parsed_body
  end

  describe "GET /api/exchange_rates" do
    it "returns 401 when not logged in" do
      get "/api/exchange_rates"

      expect(response).to have_http_status(:unauthorized)
    end

    it "lists each currency with its rate and the countries using it" do
      create(:exchange_rate, currency_code: "EUR", units_per_usd: "0.92")
      create(:country, name: "Germany", currency_code: "EUR")
      create(:country, name: "France", currency_code: "EUR")
      create(:country, name: "United States", currency_code: "USD")
      log_in(create(:user))

      get "/api/exchange_rates"

      expect(json["exchange_rates"]).to eq([
        { "currency_code" => "EUR", "units_per_usd" => "0.92", "countries" => [ "France", "Germany" ] },
        { "currency_code" => "USD", "units_per_usd" => "1.0", "countries" => [ "United States" ] }
      ])
    end
  end

  describe "PATCH /api/exchange_rates/:currency_code" do
    let!(:inr) { create(:exchange_rate, currency_code: "INR", units_per_usd: "83.25") }

    it "updates the rate" do
      log_in(create(:user))

      patch "/api/exchange_rates/INR", params: { exchange_rate: { units_per_usd: "84.1" } }, headers: csrf_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["exchange_rate"]).to include("currency_code" => "INR", "units_per_usd" => "84.1")
      expect(inr.reload.units_per_usd).to eq(BigDecimal("84.1"))
    end

    it "returns 422 for a rate of 0 or for USD" do
      create(:exchange_rate, currency_code: "USD", units_per_usd: 1)
      log_in(create(:user))
      headers = csrf_headers

      patch "/api/exchange_rates/INR", params: { exchange_rate: { units_per_usd: "0" } }, headers:, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to eq("units_per_usd" => [ "must be greater than 0" ])

      patch "/api/exchange_rates/USD", params: { exchange_rate: { units_per_usd: "2" } }, headers:, as: :json
      expect(json["errors"]).to eq("units_per_usd" => [ "must be 1 for USD" ])
      expect(inr.reload.units_per_usd).to eq(BigDecimal("83.25"))
    end

    it "returns 404 for an unknown currency and requires a CSRF token" do
      log_in(create(:user))

      patch "/api/exchange_rates/JPY", params: { exchange_rate: { units_per_usd: "150" } }, headers: csrf_headers, as: :json
      expect(response).to have_http_status(:not_found)

      patch "/api/exchange_rates/INR", params: { exchange_rate: { units_per_usd: "1" } }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(inr.reload.units_per_usd).to eq(BigDecimal("83.25"))
    end
  end
end
