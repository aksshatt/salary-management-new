require "rails_helper"

RSpec.describe SalaryRevision do
  let(:india) { create(:country, name: "India", currency_code: "INR") }
  let(:employee) { create(:employee, country: india, joined_on: Date.new(2024, 1, 15)) }

  it "takes its currency from the employee's country" do
    revision = create(:salary_revision, employee: employee)

    expect(revision.currency_code).to eq("INR")
  end

  it "keeps its currency when the employee later moves country" do
    revision = create(:salary_revision, employee: employee)
    employee.update!(country: create(:country, name: "Germany", currency_code: "EUR"))

    expect(revision.reload.currency_code).to eq("INR")
  end

  it "requires an amount, effective date and reason" do
    %i[amount effective_on reason].each do |field|
      revision = build(:salary_revision, employee: employee, field => nil)

      expect(revision).not_to be_valid
      expect(revision.errors[field]).to include("can't be blank"), "expected #{field} to be required"
    end
  end

  it "requires every column in the database" do
    %i[amount effective_on reason employee_id].each do |column|
      revision = build(:salary_revision, employee: employee, column => nil)

      expect { revision.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation), "expected #{column} NOT NULL"
    end
    expect { SalaryRevision.insert!({ employee_id: employee.id, amount: 1, effective_on: Date.current, reason: "other" }) }
      .to raise_error(ActiveRecord::NotNullViolation)
  end

  it "accepts amounts above 0 up to 1,000,000,000" do
    expect(build(:salary_revision, employee: employee, amount: "0.01")).to be_valid
    expect(build(:salary_revision, employee: employee, amount: "1000000000")).to be_valid

    %w[0 -5 1000000000.01].each do |amount|
      expect(build(:salary_revision, employee: employee, amount: amount)).not_to be_valid, "expected #{amount} to be rejected"
    end
  end

  it "enforces the amount range in the database" do
    [ 0, 1_000_000_001 ].each do |amount|
      revision = build(:salary_revision, employee: employee, amount: amount)

      expect { revision.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /salary_revisions_amount_range/)
    end
  end

  it "rejects more than 2 decimal places instead of rounding silently" do
    revision = build(:salary_revision, employee: employee, amount: "1500.555")

    expect(revision).not_to be_valid
    expect(revision.errors[:amount]).to include("can have at most 2 decimal places")
  end

  it "accepts only the known reasons" do
    %w[initial increment promotion correction other].each do |reason|
      expect(build(:salary_revision, employee: employee, reason: reason)).to be_valid, "expected #{reason} to be accepted"
    end
    expect(build(:salary_revision, employee: employee, reason: "bonus")).not_to be_valid
  end

  it "enforces the known reasons in the database" do
    revision = build(:salary_revision, employee: employee, reason: "bonus")

    expect { revision.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /salary_revisions_reason/)
  end

  it "can't be effective before the join date, but can be on it" do
    expect(build(:salary_revision, employee: employee, effective_on: Date.new(2024, 1, 15))).to be_valid

    early = build(:salary_revision, employee: employee, effective_on: Date.new(2024, 1, 14))
    expect(early).not_to be_valid
    expect(early.errors[:effective_on]).to include("can't be before the join date (2024-01-15)")
  end

  it "can't be effective after the last working day, but can be on it" do
    employee.update!(terminated_on: Date.new(2025, 6, 30))
    expect(build(:salary_revision, employee: employee, effective_on: Date.new(2025, 6, 30))).to be_valid

    late = build(:salary_revision, employee: employee, effective_on: Date.new(2025, 7, 1))
    expect(late).not_to be_valid
    expect(late.errors[:effective_on]).to include("can't be after the last working day (2025-06-30)")
  end

  it "can be dated in the future" do
    travel_to(Date.new(2026, 10, 15)) do
      expect(build(:salary_revision, employee: employee, effective_on: Date.new(2027, 4, 1), reason: "increment")).to be_valid
    end
  end

  it "can't share an effective date with another revision of the same employee" do
    create(:salary_revision, employee: employee, effective_on: Date.new(2025, 4, 1), reason: "increment")
    duplicate = build(:salary_revision, employee: employee, effective_on: Date.new(2025, 4, 1), reason: "correction")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:effective_on]).to include("already has a revision on this date")
    expect(build(:salary_revision, effective_on: Date.new(2025, 4, 1))).to be_valid
  end

  it "enforces one revision per employee per date in the database" do
    create(:salary_revision, employee: employee, effective_on: Date.new(2025, 4, 1))
    duplicate = build(:salary_revision, employee: employee, effective_on: Date.new(2025, 4, 1))

    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "can't be changed once saved" do
    revision = create(:salary_revision, employee: employee)

    expect { revision.update!(amount: 1) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect(revision.reload.amount).to eq(BigDecimal("1200000"))
  end

  it "can't be deleted once saved" do
    revision = create(:salary_revision, employee: employee)

    expect { revision.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect(SalaryRevision.exists?(revision.id)).to be(true)
  end

  it "never applies when dated after the employee's last working day" do
    on_last_day = create(:salary_revision, employee: employee, effective_on: Date.new(2025, 6, 30), reason: "increment")
    scheduled = create(:salary_revision, employee: employee, effective_on: Date.new(2025, 7, 1), reason: "increment")

    employee.terminate(on: Date.new(2025, 6, 30))

    expect([ on_last_day.reload.never_applied?, scheduled.reload.never_applied? ]).to eq([ false, true ])
  end

  it "applies normally while the employee hasn't left" do
    expect(create(:salary_revision, employee: employee).never_applied?).to be(false)
  end
end
