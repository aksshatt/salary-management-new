# What changed in an audited record, and when. Written by Auditable.
class AuditEvent < ApplicationRecord
  belongs_to :auditable, polymorphic: true
  belongs_to :employee, optional: true

  # The record of what happened is never rewritten.
  def readonly? = persisted?
end
