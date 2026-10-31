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
end
