require "rails_helper"

RSpec.describe "API audit events", type: :request do
  def json
    response.parsed_body
  end

  it "returns 401 when not logged in" do
    get "/api/audit_events"

    expect(response).to have_http_status(:unauthorized)
  end

  it "lists events newest first with what changed and a readable label" do
    employee = travel_to(Time.zone.local(2026, 10, 1, 9)) { create(:employee, name: "Priya Nair", job_title: "Engineer") }
    travel_to(Time.zone.local(2026, 10, 2, 9)) { employee.update!(job_title: "Senior Engineer") }
    log_in(create(:user))

    get "/api/audit_events"

    expect(response).to have_http_status(:ok)
    expect(json["total"]).to eq(AuditEvent.count)
    expect(json["events"].first).to eq(
      "id" => AuditEvent.where(auditable: employee, action: "update").sole.id, "type" => "Employee",
      "label" => "Priya Nair", "employee_id" => employee.id, "action" => "update",
      "changes" => { "job_title" => [ "Engineer", "Senior Engineer" ] }, "created_at" => "2026-10-02T09:00:00.000Z"
    )
  end

  it "filters by employee (including their salary revisions) and by type, 25 per page" do
    priya = create(:employee, name: "Priya Nair")
    create(:salary_revision, employee: priya)
    other = create(:employee, name: "Tom Lee")
    26.times { |i| other.update!(job_title: "Title #{i}") }
    log_in(create(:user))

    get "/api/audit_events", params: { employee_id: priya.id }
    expect(json["events"].map { |e| e["type"] }).to contain_exactly("Employee", "SalaryRevision")

    get "/api/audit_events", params: { type: "SalaryRevision" }
    expect(json["events"].map { |e| e["label"] }).to eq([ "Priya Nair" ])

    get "/api/audit_events", params: { employee_id: other.id, page: 2 }
    expect(json["total"]).to eq(27)
    expect(json["events"].size).to eq(2)
  end

  it "labels every kind of change and runs a fixed number of queries" do
    travel_to(Time.zone.local(2026, 10, 15, 9)) do
      create(:salary_revision, employee: create(:employee, name: "Priya Nair"))
      create(:exchange_rate, currency_code: "INR", units_per_usd: 83)
      create(:country, name: "India", currency_code: "INR", tax_rate_percent: 20)
      run = Payroll::Generator.new(month: Date.new(2026, 10, 1)).call.run
      run.payroll_entries.first.adjust(bonus: "5")
    end
    log_in(create(:user))

    get "/api/audit_events"
    labels = json["events"].map { |e| [ e["type"], e["label"] ] }
    expect(labels).to include(
      [ "Employee", "Priya Nair" ], [ "SalaryRevision", "Priya Nair" ], [ "PayrollRun", "Payroll 2026-10" ],
      [ "PayrollEntry", "Priya Nair (payroll 2026-10)" ], [ "Country", "India" ], [ "ExchangeRate", "INR" ]
    )

    few = count_queries { get "/api/audit_events" }
    5.times { create(:salary_revision) }
    expect(count_queries { get "/api/audit_events" }).to eq(few)
  end
end
