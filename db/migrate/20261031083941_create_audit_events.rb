class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false
      t.references :employee, foreign_key: true, index: false
      t.string :action, null: false
      t.jsonb :field_changes, null: false, default: {}

      t.datetime :created_at, null: false

      t.check_constraint "action IN ('create', 'update')", name: "audit_events_action"
    end
    add_index :audit_events, %i[auditable_type auditable_id]
    add_index :audit_events, %i[employee_id created_at]
    add_index :audit_events, :created_at
  end
end
