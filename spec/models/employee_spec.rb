require "rails_helper"

RSpec.describe Employee do
  it "is valid with all details" do
    expect(build(:employee)).to be_valid
  end

  it "gets the next sequential code when created" do
    first = create(:employee)
    second = create(:employee)

    expect(first.code).to match(/\AEMP-\d{5}\z/)
    expect(second.code.delete_prefix("EMP-").to_i).to eq(first.code.delete_prefix("EMP-").to_i + 1)
  end

  it "requires every detail" do
    %i[name email department job_title joined_on bank_account_number].each do |field|
      employee = build(:employee, field => nil)

      expect(employee).not_to be_valid
      expect(employee.errors[field]).to include("can't be blank"), "expected #{field} to be required"
    end
  end

  it "requires every detail and a country in the database" do
    %i[name email department job_title joined_on bank_account_number country_id].each do |column|
      employee = build(:employee, column => nil)

      expect { employee.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation), "expected #{column} NOT NULL"
    end
  end

  it "normalizes the email to lowercase without surrounding spaces" do
    expect(build(:employee, email: " Ana@Acme.Test ").email).to eq("ana@acme.test")
  end

  it "rejects an email already used by another employee, in any case" do
    create(:employee, email: "ana@acme.test")
    duplicate = build(:employee, email: "ANA@acme.test")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email]).to include("has already been taken")
  end

  it "enforces unique emails in the database" do
    create(:employee, email: "ana@acme.test")

    expect { build(:employee, email: "ana@acme.test").save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "rejects a last working day before the join date, but allows the same day" do
    expect(build(:employee, joined_on: Date.new(2024, 3, 1), terminated_on: Date.new(2024, 2, 29))).not_to be_valid
    expect(build(:employee, joined_on: Date.new(2024, 3, 1), terminated_on: Date.new(2024, 3, 1))).to be_valid
  end

  it "enforces the termination date rule in the database" do
    employee = build(:employee, joined_on: Date.new(2024, 3, 1), terminated_on: Date.new(2024, 2, 29))

    expect { employee.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /terminated_on_after_joined_on/)
  end

  describe "status" do
    let(:today) { Date.new(2026, 10, 15) }
    let!(:joins_today) { create(:employee, joined_on: today) }
    let!(:joins_tomorrow) { create(:employee, joined_on: today + 1) }
    let!(:leaves_today) { create(:employee, joined_on: today - 100, terminated_on: today) }
    let!(:left_yesterday) { create(:employee, joined_on: today - 100, terminated_on: today - 1) }

    around { |example| travel_to(today) { example.run } }

    it "counts as active from the join date through the last working day" do
      expect(Employee.active).to contain_exactly(joins_today, leaves_today)
    end

    it "counts as upcoming before the join date" do
      expect(Employee.upcoming).to contain_exactly(joins_tomorrow)
    end

    it "counts as terminated from the day after the last working day" do
      expect(Employee.terminated).to contain_exactly(left_yesterday)
    end

    it "reports each employee's status by name" do
      expect([ joins_today, joins_tomorrow, leaves_today, left_yesterday ].map(&:status))
        .to eq(%w[active upcoming active terminated])
    end
  end

  it "masks the bank account number to its last 4 digits" do
    expect(build(:employee, bank_account_number: "12345678901234").masked_bank_account).to eq("••••1234")
  end

  it "masks a bank account number of 4 digits or fewer completely" do
    expect(build(:employee, bank_account_number: "123").masked_bank_account).to eq("••••")
  end

  it "indexes the columns the employee list filters and sorts on" do
    indexed = ActiveRecord::Base.connection.indexes(:employees).map(&:columns)

    expect(indexed).to include([ "country_id" ], [ "department" ], [ "job_title" ], [ "joined_on" ], [ "terminated_on" ], [ "name" ])
  end

  describe "#current_revision" do
    let(:employee) { create(:employee, joined_on: Date.new(2024, 1, 15)) }
    let!(:initial) { create(:salary_revision, employee: employee, effective_on: Date.new(2024, 1, 15), amount: 1000) }
    let!(:increment) { create(:salary_revision, employee: employee, effective_on: Date.new(2025, 4, 1), amount: 1100, reason: "increment") }

    around { |example| travel_to(Date.new(2026, 10, 15)) { example.run } }

    it "is the latest revision effective on or before today, ignoring future ones" do
      create(:salary_revision, employee: employee, effective_on: Date.new(2026, 10, 16), amount: 1200, reason: "increment")

      expect(employee.current_revision).to eq(increment)
    end

    it "is the revision in effect on the last working day for someone who has left" do
      employee.update!(terminated_on: Date.new(2025, 3, 31))

      expect(employee.current_revision).to eq(initial)
    end

    it "is nil when no revision has taken effect yet" do
      upcoming = create(:employee, joined_on: Date.new(2026, 11, 1))
      create(:salary_revision, employee: upcoming, effective_on: Date.new(2026, 11, 1))

      expect(upcoming.current_revision).to be_nil
    end
  end

  it "stores the bank account number without spaces and in uppercase" do
    expect(build(:employee, bank_account_number: " de89 3704 0044 0532 ").bank_account_number).to eq("DE89370400440532")
  end

  it "accepts bank account numbers of 6 to 34 letters and digits" do
    %w[123456 DE89370400440532013000 GB82WEST12345698765432].each do |number|
      expect(build(:employee, bank_account_number: number)).to be_valid, "expected #{number} to be accepted"
    end
    [ "12345", "1" * 35, "1234-5678" ].each do |number|
      employee = build(:employee, bank_account_number: number)
      expect(employee).not_to be_valid, "expected #{number} to be rejected"
      expect(employee.errors[:bank_account_number]).to include("must be 6 to 34 letters or digits")
    end
  end

  it "can't change its join date once created" do
    employee = create(:employee, joined_on: Date.new(2024, 1, 15))

    expect(employee.update(joined_on: Date.new(2024, 2, 1))).to be(false)
    expect(employee.errors[:joined_on]).to include("can't be changed")
    expect(employee.reload.joined_on).to eq(Date.new(2024, 1, 15))
  end

  describe "#terminate" do
    let(:employee) { create(:employee, joined_on: Date.new(2024, 1, 15)) }

    context "with payroll for September (locked) and October (open)" do
      before do
        create(:payroll_run, month: Date.new(2026, 9, 1))
        create(:payroll_run, month: Date.new(2026, 10, 1))
      end

      it "can't fall in a locked payroll month" do
        expect(employee.terminate(on: Date.new(2026, 9, 30))).to be(false)
        expect(employee.errors[:terminated_on]).to include("falls in a locked payroll month (2026-09)")
        expect(employee.reload.terminated_on).to be_nil
      end

      it "can fall in the open month" do
        expect(employee.terminate(on: Date.new(2026, 10, 1))).to be(true)
      end

      it "can fall before the first payroll" do
        expect(employee.terminate(on: Date.new(2026, 8, 31))).to be(true)
      end
    end

    it "sets the last working day, which can be the join date" do
      expect(employee.terminate(on: Date.new(2024, 1, 15))).to be(true)
      expect(employee.reload.terminated_on).to eq(Date.new(2024, 1, 15))
    end

    it "requires a date" do
      expect(employee.terminate(on: nil)).to be(false)
      expect(employee.errors[:terminated_on]).to include("can't be blank")
    end

    it "rejects a date before the join date" do
      expect(employee.terminate(on: Date.new(2024, 1, 14))).to be(false)
      expect(employee.reload.terminated_on).to be_nil
    end

    it "can't terminate twice or change the date" do
      employee.terminate(on: Date.new(2025, 6, 30))

      expect(employee.terminate(on: Date.new(2025, 7, 31))).to be(false)
      expect(employee.errors[:terminated_on]).to include("already terminated")
      expect(employee.reload.terminated_on).to eq(Date.new(2025, 6, 30))
    end
  end

  it "pads short ids to 5 digits but never cuts long ones" do
    expect([ create(:employee, id: 42).code, create(:employee, id: 123_456).code ]).to eq(%w[EMP-00042 EMP-123456])
  end

  it "guarantees unique codes in the database" do
    code_index = ActiveRecord::Base.connection.indexes(:employees).find { |index| index.columns == [ "code" ] }

    expect(code_index&.unique).to be(true)
  end
end
