require "rails_helper"

RSpec.describe "API countries", type: :request do
  def json
    response.parsed_body
  end

  describe "GET /api/countries" do
    it "returns 401 when not logged in" do
      get "/api/countries"

      expect(response).to have_http_status(:unauthorized)
    end

    it "lists countries by name with their currency and tax rate" do
      create(:exchange_rate, currency_code: "INR", units_per_usd: "83.25")
      india = create(:country, name: "India", currency_code: "INR", tax_rate_percent: "20")
      brazil = create(:country, name: "Brazil", currency_code: "USD", tax_rate_percent: "27.5")
      log_in(create(:user))

      get "/api/countries"

      expect(json["countries"]).to eq([
        { "id" => brazil.id, "name" => "Brazil", "currency_code" => "USD", "tax_rate_percent" => "27.50" },
        { "id" => india.id, "name" => "India", "currency_code" => "INR", "tax_rate_percent" => "20.00" }
      ])
    end
  end

  describe "PATCH /api/countries/:id" do
    let!(:country) { create(:country, name: "India", currency_code: "USD", tax_rate_percent: "20") }

    it "updates the tax rate" do
      log_in(create(:user))

      patch "/api/countries/#{country.id}", params: { country: { tax_rate_percent: "22.5" } }, headers: csrf_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["country"]).to include("name" => "India", "tax_rate_percent" => "22.50")
      expect(country.reload.tax_rate_percent).to eq(BigDecimal("22.5"))
    end

    it "returns 422 for an invalid rate and ignores other fields" do
      log_in(create(:user))
      headers = csrf_headers

      patch "/api/countries/#{country.id}", params: { country: { tax_rate_percent: "101" } }, headers:, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to eq("tax_rate_percent" => [ "must be less than or equal to 100" ])

      patch "/api/countries/#{country.id}", params: { country: { tax_rate_percent: "21", name: "X", currency_code: "EUR" } }, headers:, as: :json
      expect(country.reload).to have_attributes(name: "India", currency_code: "USD", tax_rate_percent: BigDecimal("21"))
    end

    it "returns 404 for an unknown country and requires a CSRF token" do
      log_in(create(:user))

      patch "/api/countries/0", params: { country: { tax_rate_percent: "21" } }, headers: csrf_headers, as: :json
      expect(response).to have_http_status(:not_found)

      patch "/api/countries/#{country.id}", params: { country: { tax_rate_percent: "21" } }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(country.reload.tax_rate_percent).to eq(BigDecimal("20"))
    end
  end
end
