class CreateSalaryRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :salary_revisions do |t|
      t.references :employee, null: false, foreign_key: true, index: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :currency_code, null: false
      t.date :effective_on, null: false
      t.string :reason, null: false

      t.timestamps

      t.check_constraint "amount > 0 AND amount <= 1000000000", name: "salary_revisions_amount_range"
      t.check_constraint "reason IN ('initial', 'increment', 'promotion', 'correction', 'other')",
        name: "salary_revisions_reason"
    end
    # Also serves lookups by employee, so no separate employee_id index.
    add_index :salary_revisions, %i[employee_id effective_on], unique: true
  end
end
