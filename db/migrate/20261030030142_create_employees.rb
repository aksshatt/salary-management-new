class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      # Derived from the primary key, so it's unique and never typed by hand.
      t.virtual :code, type: :string, as: "'EMP-' || lpad(id::text, 5, '0')", stored: true
      t.string :name, null: false
      t.string :email, null: false
      t.references :country, null: false, foreign_key: true
      t.string :department, null: false
      t.string :job_title, null: false
      t.date :joined_on, null: false
      t.date :terminated_on
      t.string :bank_account_number, null: false

      t.timestamps

      t.check_constraint "terminated_on IS NULL OR terminated_on >= joined_on", name: "terminated_on_after_joined_on"
    end
    add_index :employees, :email, unique: true
    add_index :employees, :name
    add_index :employees, :department
    add_index :employees, :job_title
    add_index :employees, :joined_on
    add_index :employees, :terminated_on
  end
end
