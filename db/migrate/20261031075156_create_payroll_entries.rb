class CreatePayrollEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :payroll_entries do |t|
      t.references :payroll_run, null: false, foreign_key: true, index: false
      t.references :employee, null: false, foreign_key: true
      t.references :salary_revision, null: false, foreign_key: true
      t.string :currency_code, null: false
      t.decimal :annual_salary, precision: 12, scale: 2, null: false
      t.decimal :tax_rate_percent, precision: 5, scale: 2, null: false
      t.integer :days_worked, null: false
      t.integer :days_in_month, null: false
      t.decimal :monthly_gross, precision: 12, scale: 2, null: false
      t.decimal :bonus, precision: 12, scale: 2, null: false, default: 0
      t.decimal :deduction, precision: 12, scale: 2, null: false, default: 0
      t.text :note
      t.decimal :tax, precision: 12, scale: 2, null: false
      t.decimal :net, precision: 12, scale: 2, null: false

      t.timestamps

      t.check_constraint "days_in_month BETWEEN 28 AND 31 AND days_worked BETWEEN 1 AND days_in_month",
        name: "payroll_entries_days_worked"
      t.check_constraint "bonus >= 0", name: "payroll_entries_bonus"
      t.check_constraint "deduction >= 0", name: "payroll_entries_deduction"
    end
    # Also serves lookups by run.
    add_index :payroll_entries, %i[payroll_run_id employee_id], unique: true
  end
end
