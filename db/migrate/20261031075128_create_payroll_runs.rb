class CreatePayrollRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :payroll_runs do |t|
      t.date :month, null: false
      t.datetime :calculated_at, null: false

      t.timestamps

      t.check_constraint "EXTRACT(DAY FROM month) = 1", name: "payroll_runs_month_first_day"
    end
    add_index :payroll_runs, :month, unique: true
  end
end
