require "rails_helper"

RSpec.describe "Audit trail" do
  def events_for(record)
    AuditEvent.where(auditable: record).order(:id)
  end

  describe "employees" do
    it "records the details of a new employee" do
      employee = create(:employee, name: "Priya Nair", department: "Sales", joined_on: Date.new(2024, 1, 15))

      event = events_for(employee).sole
      expect(event).to have_attributes(action: "create", employee_id: employee.id)
      expect(event.field_changes).to include(
        "name" => [ nil, "Priya Nair" ], "department" => [ nil, "Sales" ], "joined_on" => [ nil, "2024-01-15" ]
      )
      expect(event.field_changes.keys).not_to include("created_at", "updated_at", "id")
    end

    it "records an edit with the old and new values, and termination as a change of last working day" do
      employee = create(:employee, job_title: "Engineer", joined_on: Date.new(2024, 1, 15))

      employee.update!(job_title: "Senior Engineer")
      employee.terminate(on: Date.new(2026, 10, 31))

      expect(events_for(employee).where(action: "update").map(&:field_changes)).to eq([
        { "job_title" => [ "Engineer", "Senior Engineer" ] },
        { "terminated_on" => [ nil, "2026-10-31" ] }
      ])
    end

    it "never stores a full bank account number" do
      employee = create(:employee, bank_account_number: "123456789012")
      employee.update!(bank_account_number: "DE89370400440532013000")

      changes = events_for(employee).map { |event| event.field_changes["bank_account_number"] }
      expect(changes).to eq([ [ nil, "••••9012" ], [ "••••9012", "••••3000" ] ])
      expect(AuditEvent.pluck(:field_changes).to_s).not_to include("123456789012", "DE89370400440532013000")
    end

    it "records nothing when nothing changed or the change is invalid" do
      employee = create(:employee)

      employee.update!(name: employee.name)
      employee.update(name: "")

      expect(events_for(employee).where(action: "update")).to be_empty
    end
  end

  it "records a new salary revision against its employee" do
    revision = create(:salary_revision, amount: "1320000.50", reason: "initial")

    expect(events_for(revision).sole).to have_attributes(action: "create", employee_id: revision.employee_id)
    expect(events_for(revision).sole.field_changes).to include("amount" => [ nil, "1320000.5" ], "reason" => [ nil, "initial" ])
  end

  it "records exchange rate and tax rate changes" do
    rate = create(:exchange_rate, currency_code: "INR", units_per_usd: "83.25")
    country = create(:country, name: "India", currency_code: "INR", tax_rate_percent: "20")

    rate.update!(units_per_usd: "84")
    country.update!(tax_rate_percent: "22.5")

    expect(events_for(rate).last.field_changes).to eq("units_per_usd" => [ "83.25", "84.0" ])
    expect(events_for(country).last.field_changes).to eq("tax_rate_percent" => [ "20.0", "22.5" ])
  end

  describe "payroll" do
    around { |example| travel_to(Time.zone.local(2026, 10, 15, 9)) { example.run } }

    let!(:revision) { create(:salary_revision) }

    it "records a run when it is generated and each time it is recalculated, not every entry" do
      run = Payroll::Generator.new(month: Date.new(2026, 10, 1)).call.run
      travel 1.hour
      Payroll::Generator.new(month: Date.new(2026, 10, 1)).call

      expect(events_for(run).map(&:action)).to eq(%w[create update])
      expect(events_for(run).last.field_changes).to eq("calculated_at" => [ "2026-10-15T09:00:00Z", "2026-10-15T10:00:00Z" ])
      expect(AuditEvent.where(auditable_type: "PayrollEntry")).to be_empty
    end

    it "records HR's adjustments to an entry against the employee" do
      entry = Payroll::Generator.new(month: Date.new(2026, 10, 1)).call.run.payroll_entries.sole

      entry.adjust(bonus: "1000", note: "Spot award")

      event = events_for(entry).sole
      expect(event).to have_attributes(action: "update", employee_id: revision.employee_id)
      expect(event.field_changes).to include("bonus" => [ "0.0", "1000.0" ], "note" => [ nil, "Spot award" ])
    end
  end

  it "keeps events as they were: they can't be changed or deleted" do
    event = events_for(create(:employee)).sole

    expect { event.update!(action: "update") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { event.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "leaves no event when the change is rolled back" do
    ActiveRecord::Base.transaction do
      create(:employee)
      raise ActiveRecord::Rollback
    end

    expect(AuditEvent.count).to eq(0)
  end
end
