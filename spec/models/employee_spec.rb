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
end
