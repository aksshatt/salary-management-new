require "rails_helper"

RSpec.describe "API employees", type: :request do
  let(:india) { create(:country, name: "India", currency_code: "INR") }

  def log_in_as_hr
    log_in(create(:user))
  end

  def json
    response.parsed_body
  end

  describe "GET /api/employees" do
    around { |example| travel_to(Date.new(2026, 10, 15)) { example.run } }

    it "returns 401 when not logged in" do
      get "/api/employees"

      expect(response).to have_http_status(:unauthorized)
    end

    it "lists employees by name with their country, status and masked bank account" do
      zoe = create(:employee, name: "Zoe Park", email: "zoe@acme.test", country: india, department: "Sales",
        job_title: "Account Manager", joined_on: Date.new(2025, 1, 6), bank_account_number: "9876543210")
      create(:employee, name: "Amit Shah")
      log_in_as_hr

      get "/api/employees"

      expect(response).to have_http_status(:ok)
      expect(json["total"]).to eq(2)
      expect(json["employees"].map { |e| e["name"] }).to eq([ "Amit Shah", "Zoe Park" ])
      expect(json["employees"].last).to eq(
        "id" => zoe.id, "code" => zoe.code, "name" => "Zoe Park", "email" => "zoe@acme.test",
        "country" => { "id" => india.id, "name" => "India", "currency_code" => "INR" },
        "department" => "Sales", "job_title" => "Account Manager", "joined_on" => "2025-01-06",
        "terminated_on" => nil, "status" => "active", "bank_account" => "••••3210"
      )
      expect(response.body).not_to include("9876543210")
    end

    it "runs the same number of queries for 3 or 30 employees" do
      log_in_as_hr
      create_list(:employee, 3)
      few = count_queries { get "/api/employees" }
      create_list(:employee, 27)
      many = count_queries { get "/api/employees" }

      expect(many).to eq(few)
    end

    it "returns 25 employees per page with the full total" do
      log_in_as_hr
      26.times { |i| create(:employee, name: format("Person %02d", i + 1)) }

      get "/api/employees", params: { page: 2 }

      expect(json["total"]).to eq(26)
      expect(json["page"]).to eq(2)
      expect(json["per_page"]).to eq(25)
      expect(json["employees"].map { |e| e["name"] }).to eq([ "Person 26" ])
    end

    it "treats a missing, zero or non-numeric page as page 1" do
      log_in_as_hr
      create(:employee)

      [ nil, "0", "-3", "abc" ].each do |page|
        get "/api/employees", params: { page: page }.compact

        expect(json["page"]).to eq(1), "page=#{page.inspect}"
        expect(json["employees"].size).to eq(1)
      end
    end

    it "returns no employees but the real total past the last page" do
      log_in_as_hr
      create(:employee)

      get "/api/employees", params: { page: 5 }

      expect(json["employees"]).to eq([])
      expect(json["total"]).to eq(1)
    end

    it "searches by part of the name, ignoring case" do
      log_in_as_hr
      create(:employee, name: "Priya Nair")
      create(:employee, name: "Tom Lee")

      get "/api/employees", params: { q: "NAI" }

      expect(json["employees"].map { |e| e["name"] }).to eq([ "Priya Nair" ])
      expect(json["total"]).to eq(1)
    end

    it "searches by employee code" do
      log_in_as_hr
      target = create(:employee, name: "Priya Nair")
      create(:employee, name: "Tom Lee")

      get "/api/employees", params: { q: target.code.downcase }

      expect(json["employees"].map { |e| e["name"] }).to eq([ "Priya Nair" ])
    end

    it "treats % and _ in the search as plain characters" do
      log_in_as_hr
      create(:employee, name: "Ana 100% Sales")
      create(:employee, name: "Bo Chen")

      get "/api/employees", params: { q: "%" }

      expect(json["employees"].map { |e| e["name"] }).to eq([ "Ana 100% Sales" ])
    end

    it "ignores spaces around the search text" do
      log_in_as_hr
      create(:employee, name: "Priya Nair")
      create(:employee, name: "Tom Lee")

      get "/api/employees", params: { q: "  nair " }

      expect(json["employees"].map { |e| e["name"] }).to eq([ "Priya Nair" ])
    end

    it "filters by country" do
      log_in_as_hr
      create(:employee, name: "In India", country: india)
      create(:employee, name: "Elsewhere")

      get "/api/employees", params: { country_id: india.id }

      expect(json["employees"].map { |e| e["name"] }).to eq([ "In India" ])
    end

    it "filters by exact department" do
      log_in_as_hr
      create(:employee, name: "In Sales", department: "Sales")
      create(:employee, name: "In Sales Ops", department: "Sales Ops")

      get "/api/employees", params: { department: "Sales" }

      expect(json["employees"].map { |e| e["name"] }).to eq([ "In Sales" ])
    end

    it "filters by exact job title" do
      log_in_as_hr
      create(:employee, name: "Engineer", job_title: "Engineer")
      create(:employee, name: "Senior", job_title: "Senior Engineer")

      get "/api/employees", params: { job_title: "Engineer" }

      expect(json["employees"].map { |e| e["name"] }).to eq([ "Engineer" ])
    end

    it "filters by status" do
      log_in_as_hr
      create(:employee, name: "Current", joined_on: Date.new(2025, 1, 1))
      create(:employee, name: "Starting", joined_on: Date.new(2026, 11, 1))
      create(:employee, name: "Gone", joined_on: Date.new(2025, 1, 1), terminated_on: Date.new(2026, 9, 30))

      results = %w[active upcoming terminated].to_h do |status|
        get "/api/employees", params: { status: status }
        [ status, json["employees"].map { |e| e["name"] } ]
      end

      expect(results).to eq("active" => [ "Current" ], "upcoming" => [ "Starting" ], "terminated" => [ "Gone" ])
    end

    it "ignores an unknown status instead of calling it" do
      log_in_as_hr
      create(:employee)

      get "/api/employees", params: { status: "delete_all" }

      expect(json["total"]).to eq(1)
      expect(Employee.count).to eq(1)
    end

    it "combines search and filters" do
      log_in_as_hr
      create(:employee, name: "Priya Sales", country: india, department: "Sales")
      create(:employee, name: "Priya Eng", country: india, department: "Engineering")
      create(:employee, name: "Priya Abroad", department: "Sales")

      get "/api/employees", params: { q: "priya", country_id: india.id, department: "Sales" }

      expect(json["employees"].map { |e| e["name"] }).to eq([ "Priya Sales" ])
    end
  end
end
