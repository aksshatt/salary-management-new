require "rails_helper"

RSpec.describe PayrollEntry do
  it "is valid with its run, employee, revision and amounts, starting with no bonus or deduction" do
    entry = create(:payroll_entry)

    expect(entry).to be_valid
    expect(entry).to have_attributes(bonus: 0, deduction: 0, note: nil)
  end

  it "requires its stored inputs and amounts" do
    %i[currency_code annual_salary tax_rate_percent days_worked days_in_month monthly_gross tax net].each do |field|
      expect(build(:payroll_entry, field => nil)).not_to be_valid, "expected #{field} to be required"
    end
  end

  it "keeps days worked between 1 and the days in the month" do
    expect(build(:payroll_entry, days_worked: 0)).not_to be_valid
    expect(build(:payroll_entry, days_worked: 31, days_in_month: 30)).not_to be_valid
    expect(build(:payroll_entry, days_worked: 1, days_in_month: 28)).to be_valid
  end

  it "doesn't allow a negative bonus or deduction, or more than 2 decimals" do
    expect(build(:payroll_entry, bonus: -1)).not_to be_valid
    expect(build(:payroll_entry, deduction: -1)).not_to be_valid
    expect(build(:payroll_entry, bonus: "10.005")).not_to be_valid
  end

  it "has one entry per employee per run" do
    entry = create(:payroll_entry)

    expect(build(:payroll_entry, payroll_run: entry.payroll_run, employee: entry.employee, salary_revision: entry.salary_revision)).not_to be_valid
  end

  it "enforces the rules in the database" do
    entry = create(:payroll_entry)
    months = (1..).lazy.map { |n| Date.new(2020, 1, 1) >> n }
    save = ->(attrs) { build(:payroll_entry, payroll_run: create(:payroll_run, month: months.next), **attrs).save(validate: false) }

    expect { build(:payroll_entry, payroll_run: entry.payroll_run, employee: entry.employee, salary_revision: entry.salary_revision).save(validate: false) }
      .to raise_error(ActiveRecord::RecordNotUnique)
    expect { save.call(days_worked: 0) }.to raise_error(ActiveRecord::StatementInvalid, /payroll_entries_days_worked/)
    expect { save.call(bonus: -1) }.to raise_error(ActiveRecord::StatementInvalid, /payroll_entries_bonus/)
    expect { save.call(deduction: -1) }.to raise_error(ActiveRecord::StatementInvalid, /payroll_entries_deduction/)
    %i[currency_code annual_salary tax_rate_percent monthly_gross tax net bonus].each do |column|
      expect { save.call(column => nil) }.to raise_error(ActiveRecord::NotNullViolation), "expected #{column} NOT NULL"
    end
  end

  it "can only be changed while its month is the latest (open) one" do
    september = create(:payroll_entry, payroll_run: create(:payroll_run, month: Date.new(2026, 9, 1)))
    october = create(:payroll_entry, payroll_run: create(:payroll_run, month: Date.new(2026, 10, 1)))

    expect { september.update!(bonus: 100) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect(october.update!(bonus: 100)).to be(true)
  end

  describe "#adjust" do
    let(:entry) do
      create(:payroll_entry, annual_salary: 120_000, tax_rate_percent: 25, days_worked: 30, days_in_month: 30,
        monthly_gross: 10_000, tax: 2_500, net: 7_500)
    end

    it "recalculates tax and net from the entry's own stored inputs" do
      create(:salary_revision, employee: entry.employee, effective_on: entry.employee.joined_on + 10, amount: 999_999, reason: "increment")

      expect(entry.adjust(bonus: "1000", deduction: "300", note: "Spot award")).to be(true)
      expect(entry.reload).to have_attributes(
        monthly_gross: 10_000, bonus: 1000, deduction: 300, note: "Spot award", tax: 2_750, net: 7_950
      )
    end

    it "flags a negative net, which is allowed for loan recovery" do
      entry.adjust(bonus: "0", deduction: "8000", note: "Advance recovery")

      expect(entry.reload).to have_attributes(net: -500, negative_net?: true)
    end

    it "changes nothing when the input is invalid, and limits notes to 500 characters" do
      expect(entry.adjust(bonus: "-1", deduction: "0", note: nil)).to be(false)
      expect(entry.adjust(bonus: "0", deduction: "0", note: "x" * 501)).to be(false)
      expect(entry.errors[:note]).to include("is too long (maximum is 500 characters)")
      expect(entry.reload).to have_attributes(bonus: 0, net: 7_500, note: nil)
    end
  end
end
