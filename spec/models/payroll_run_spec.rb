require "rails_helper"

RSpec.describe PayrollRun do
  it "is for the first day of a month" do
    expect(build(:payroll_run, month: Date.new(2026, 9, 1))).to be_valid
  end

  it "requires a month that starts on the 1st and a calculation time" do
    expect(build(:payroll_run, month: nil)).not_to be_valid
    expect(build(:payroll_run, calculated_at: nil)).not_to be_valid

    mid_month = build(:payroll_run, month: Date.new(2026, 9, 15))
    expect(mid_month).not_to be_valid
    expect(mid_month.errors[:month]).to include("must be the first day of a month")
  end

  it "has at most one run per month" do
    create(:payroll_run, month: Date.new(2026, 9, 1))

    expect(build(:payroll_run, month: Date.new(2026, 9, 1))).not_to be_valid
  end

  it "enforces the rules in the database" do
    create(:payroll_run, month: Date.new(2026, 9, 1))

    expect { build(:payroll_run, month: Date.new(2026, 9, 1)).save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    expect { build(:payroll_run, month: Date.new(2026, 8, 2)).save(validate: false) }
      .to raise_error(ActiveRecord::StatementInvalid, /payroll_runs_month_first_day/)
    expect { build(:payroll_run, month: nil).save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    expect { build(:payroll_run, month: Date.new(2026, 7, 1), calculated_at: nil).save(validate: false) }
      .to raise_error(ActiveRecord::NotNullViolation)
  end

  it "is open only while it is the latest month; older months are locked" do
    september = create(:payroll_run, month: Date.new(2026, 9, 1))
    october = create(:payroll_run, month: Date.new(2026, 10, 1))

    expect([ september.open?, october.open? ]).to eq([ false, true ])
  end

  describe "#outdated?" do
    # Data created before the run was calculated.
    let!(:employee) { travel_to(2.hours.ago) { create(:salary_revision).employee } }
    let(:run) { create(:payroll_run, month: Date.new(2026, 10, 1), calculated_at: 1.hour.ago) }

    it "is false when nothing changed after the last calculation" do
      run

      expect(run.outdated?).to be(false)
    end

    it "is true after a new salary revision" do
      run
      create(:salary_revision, employee:, effective_on: employee.joined_on + 30, reason: "increment")

      expect(run.outdated?).to be(true)
    end

    it "is true after an employee is added, edited or terminated" do
      run
      employee.terminate(on: Date.current)

      expect(run.outdated?).to be(true)
    end

    it "is true after a country's tax rate changes, but not after an exchange rate change" do
      run
      ExchangeRate.find_or_create_by!(currency_code: "USD") { |rate| rate.units_per_usd = 1 }.touch
      expect(run.outdated?).to be(false)

      employee.country.update!(tax_rate_percent: 33)
      expect(run.outdated?).to be(true)
    end

    it "is false again once recalculated" do
      run
      employee.terminate(on: Date.current)
      run.update!(calculated_at: Time.current)

      expect(run.outdated?).to be(false)
    end
  end
end
