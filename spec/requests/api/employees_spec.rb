require "rails_helper"

RSpec.describe "API employees", type: :request do
  let(:india) do
    create(:exchange_rate, currency_code: "INR", units_per_usd: "83.25")
    create(:country, name: "India", currency_code: "INR")
  end

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
        "terminated_on" => nil, "status" => "active", "bank_account" => "••••3210", "current_salary" => nil
      )
      expect(response.body).not_to include("9876543210")
    end

    it "includes each employee's current salary, or null when none has taken effect" do
      paid = create(:employee, name: "Paid", country: india, joined_on: Date.new(2024, 1, 15))
      create(:salary_revision, employee: paid, effective_on: Date.new(2024, 1, 15), amount: "1000")
      create(:salary_revision, employee: paid, effective_on: Date.new(2025, 4, 1), amount: "1100", reason: "increment")
      create(:salary_revision, employee: paid, effective_on: Date.new(2027, 1, 1), amount: "1200", reason: "increment")
      left = create(:employee, name: "Left", country: india, joined_on: Date.new(2024, 1, 15), terminated_on: Date.new(2025, 3, 31))
      create(:salary_revision, employee: left, effective_on: Date.new(2024, 1, 15), amount: "900")
      create(:salary_revision, employee: left, effective_on: Date.new(2025, 3, 31), amount: "950", reason: "correction")
      create(:employee, name: "Starting", joined_on: Date.new(2026, 11, 1))
      log_in_as_hr

      get "/api/employees"

      salaries = json["employees"].to_h { |e| [ e["name"], e["current_salary"] ] }
      expect(salaries).to eq(
        "Left" => { "amount" => "950.00", "currency_code" => "INR", "usd" => "11.41" },
        "Paid" => { "amount" => "1100.00", "currency_code" => "INR", "usd" => "13.21" },
        "Starting" => nil
      )
    end

    it "uses the app's date, not the database clock, for the current salary" do
      employee = create(:employee, name: "Tomorrow's raise", joined_on: Date.new(2024, 1, 15))
      create(:salary_revision, employee: employee, effective_on: Date.new(2024, 1, 15), amount: "1000")
      create(:salary_revision, employee: employee, effective_on: Date.new(2026, 10, 16), amount: "2000", reason: "increment")
      log_in_as_hr

      get "/api/employees"

      expect(json["employees"].first["current_salary"]["amount"]).to eq("1000.00")
    end

    it "still shows the local salary when its currency has no exchange rate" do
      employee = create(:employee, name: "No rate", country: india, joined_on: Date.new(2024, 1, 15))
      create(:salary_revision, employee: employee, effective_on: Date.new(2024, 1, 15), amount: "1000")
      ExchangeRate.where(currency_code: "INR").delete_all
      log_in_as_hr

      get "/api/employees"

      expect(json["employees"].first["current_salary"]).to eq("amount" => "1000.00", "currency_code" => "INR", "usd" => nil)
    end

    it "runs the same number of queries for 3 or 30 employees" do
      log_in_as_hr
      create_list(:salary_revision, 3)
      few = count_queries { get "/api/employees" }
      create_list(:salary_revision, 27)
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

  describe "GET /api/employees/:id" do
    around { |example| travel_to(Date.new(2026, 10, 15)) { example.run } }

    let(:employee) { create(:employee, country: india, joined_on: Date.new(2024, 1, 15), bank_account_number: "9876543210") }

    it "returns 401 when not logged in" do
      get "/api/employees/#{employee.id}"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the employee with current salary and revision history, newest first" do
      initial = create(:salary_revision, employee: employee, effective_on: Date.new(2024, 1, 15), amount: "1200000")
      increment = create(:salary_revision, employee: employee, effective_on: Date.new(2025, 4, 1), amount: "1320000.50",
        reason: "increment")
      future = create(:salary_revision, employee: employee, effective_on: Date.new(2027, 4, 1), amount: "1400000",
        reason: "promotion")
      log_in_as_hr

      get "/api/employees/#{employee.id}"

      expect(response).to have_http_status(:ok)
      expect(json["employee"]).to include("id" => employee.id, "code" => employee.code, "bank_account" => "••••3210")
      expect(json["employee"]["current_salary"]).to eq("amount" => "1320000.50", "currency_code" => "INR", "usd" => "15855.86")
      expect(json["employee"]["salary_revisions"]).to eq([
        { "id" => future.id, "effective_on" => "2027-04-01", "amount" => "1400000.00", "currency_code" => "INR", "reason" => "promotion",
          "never_applied" => false },
        { "id" => increment.id, "effective_on" => "2025-04-01", "amount" => "1320000.50", "currency_code" => "INR", "reason" => "increment",
          "never_applied" => false },
        { "id" => initial.id, "effective_on" => "2024-01-15", "amount" => "1200000.00", "currency_code" => "INR", "reason" => "initial",
          "never_applied" => false }
      ])
      expect(response.body).not_to include("9876543210")
    end

    it "flags revisions dated after the last working day as never applied" do
      create(:salary_revision, employee: employee, effective_on: Date.new(2024, 1, 15))
      create(:salary_revision, employee: employee, effective_on: Date.new(2026, 11, 1), reason: "increment")
      employee.terminate(on: Date.new(2026, 10, 31))
      log_in_as_hr

      get "/api/employees/#{employee.id}"

      expect(json["employee"]["salary_revisions"].map { |r| [ r["effective_on"], r["never_applied"] ] })
        .to eq([ [ "2026-11-01", true ], [ "2024-01-15", false ] ])
    end

    it "shows the local salary without USD when its currency has no exchange rate" do
      create(:salary_revision, employee: employee, effective_on: Date.new(2024, 1, 15), amount: "1000")
      ExchangeRate.where(currency_code: "INR").delete_all
      log_in_as_hr

      get "/api/employees/#{employee.id}"

      expect(response).to have_http_status(:ok)
      expect(json["employee"]["current_salary"]).to eq("amount" => "1000.00", "currency_code" => "INR", "usd" => nil)
    end

    it "returns a JSON 404 for an unknown employee" do
      log_in_as_hr

      get "/api/employees/0"

      expect(response).to have_http_status(:not_found)
      expect(json).to eq("error" => "Not found")
    end
  end

  describe "POST /api/employees" do
    let(:employee_params) do
      {
        employee: {
          name: "Priya Nair", email: "priya@acme.test", country_id: india.id, department: "Sales",
          job_title: "Account Manager", joined_on: "2026-11-02", bank_account_number: "1234 5678 9012"
        },
        initial_salary: "1200000"
      }
    end

    it "returns 401 when not logged in" do
      post "/api/employees", params: employee_params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "creates the employee with their initial salary" do
      log_in_as_hr

      post "/api/employees", params: employee_params, headers: csrf_headers, as: :json

      expect(response).to have_http_status(:created)
      created = Employee.find(json["employee"]["id"])
      expect(json["employee"]).to include("code" => created.code, "name" => "Priya Nair", "bank_account" => "••••9012")
      expect(created.bank_account_number).to eq("123456789012")
      expect(created.salary_revisions.pluck(:amount, :reason)).to eq([ [ BigDecimal("1200000"), "initial" ] ])
    end

    it "returns 422 with every field error and saves nothing" do
      log_in_as_hr
      employee_params[:employee].merge!(name: "", country_id: 0)
      employee_params[:initial_salary] = ""

      post "/api/employees", params: employee_params, headers: csrf_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to eq(
        "name" => [ "can't be blank" ], "country" => [ "must exist" ], "initial_salary" => [ "can't be blank" ]
      )
      expect(Employee.count).to eq(0)
    end

    it "ignores fields HR can't set, like the code or a last working day" do
      log_in_as_hr
      employee_params[:employee].merge!(code: "EMP-99999", terminated_on: "2026-12-31")

      post "/api/employees", params: employee_params, headers: csrf_headers, as: :json

      created = Employee.find(json["employee"]["id"])
      expect(created.code).not_to eq("EMP-99999")
      expect(created.terminated_on).to be_nil
    end
  end

  describe "PATCH /api/employees/:id" do
    let(:employee) do
      create(:employee, name: "Priya Nair", email: "priya@acme.test", country: india, joined_on: Date.new(2024, 1, 15),
        bank_account_number: "123456789012")
    end
    let(:path) { "/api/employees/#{employee.id}" }

    it "returns 401 when not logged in" do
      patch path, params: { employee: { name: "Priya N." } }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "updates the editable details" do
      germany = create(:country, name: "Germany", currency_code: "EUR")
      log_in_as_hr

      patch path, params: { employee: { name: "Priya N.", email: "PNair@acme.test", country_id: germany.id,
        department: "Partnerships", job_title: "Partner Manager", bank_account_number: "de89 3704 0044 0532" } },
        headers: csrf_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["employee"]).to include("name" => "Priya N.", "email" => "pnair@acme.test", "bank_account" => "••••0532")
      expect(employee.reload).to have_attributes(country: germany, department: "Partnerships",
        job_title: "Partner Manager", bank_account_number: "DE89370400440532")
    end

    it "keeps the bank account number when it's left out" do
      log_in_as_hr

      patch path, params: { employee: { name: "Priya N." } }, headers: csrf_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(employee.reload).to have_attributes(name: "Priya N.", bank_account_number: "123456789012")
    end

    it "rejects a change to the join date" do
      log_in_as_hr

      patch path, params: { employee: { joined_on: "2024-02-01" } }, headers: csrf_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to eq("joined_on" => [ "can't be changed" ])
      expect(employee.reload.joined_on).to eq(Date.new(2024, 1, 15))
    end

    it "rejects an email used by another employee" do
      create(:employee, email: "taken@acme.test")
      log_in_as_hr

      patch path, params: { employee: { email: "taken@acme.test" } }, headers: csrf_headers, as: :json

      expect(json["errors"]).to eq("email" => [ "has already been taken" ])
    end

    it "returns 404 for an unknown employee" do
      log_in_as_hr

      patch "/api/employees/0", params: { employee: { name: "X" } }, headers: csrf_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "requires a CSRF token" do
      log_in_as_hr

      patch path, params: { employee: { name: "X" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(employee.reload.name).to eq("Priya Nair")
    end
  end
end
