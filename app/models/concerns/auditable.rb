# Records an AuditEvent with the changed fields (old and new values) whenever
# the record is created or updated. Runs inside the same transaction, so a
# rolled-back save leaves no event.
module Auditable
  extend ActiveSupport::Concern

  IGNORED = %w[id created_at updated_at].freeze

  # Attributes stored masked in the audit, each with the class method that
  # masks it, e.g. `audit_masked bank_account_number: :mask_bank_account`.
  class_methods do
    def audit_masked(maskers)
      @audit_maskers = maskers.transform_keys(&:to_s)
    end

    def audit_maskers
      @audit_maskers || {}
    end
  end

  included do
    after_create { record_audit_event("create") }
    after_update { record_audit_event("update") }
  end

  private
    def record_audit_event(action)
      changes = saved_changes.except(*IGNORED)
      return if changes.empty?

      AuditEvent.create!(auditable: self, employee_id: audit_employee_id, action:,
        field_changes: changes.to_h { |attribute, values| [ attribute, values.map { |value| audit_value(attribute, value) } ] })
    end

    def audit_employee_id
      self.class == Employee ? id : try(:employee_id)
    end

    # Exact strings: decimals without float rounding, dates as ISO 8601.
    def audit_value(attribute, value)
      masker = self.class.audit_maskers[attribute]
      return value && self.class.public_send(masker, value) if masker

      case value
      when BigDecimal then value.to_s("F")
      when Date, Time then value.iso8601
      else value
      end
    end
end
