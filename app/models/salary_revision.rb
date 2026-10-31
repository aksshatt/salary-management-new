class SalaryRevision < ApplicationRecord
  REASONS = %w[initial increment promotion correction other].freeze

  belongs_to :employee

  validates :amount, :effective_on, :reason, presence: true
  validates :reason, inclusion: { in: REASONS }, allow_nil: true
  validates :effective_on, uniqueness: { scope: :employee_id, message: "already has a revision on this date" }
  validates :amount, numericality: { greater_than: 0, less_than_or_equal_to: 1_000_000_000 }, allow_nil: true

  validates :amount, decimal_places: 2
  validate :effective_within_employment

  before_create { self.currency_code = employee&.country&.currency_code }

  # History must stay accurate: a change is a new revision, never an edit.
  def readonly? = persisted?

  # % change of each revision from the previous one by date: { id => BigDecimal or nil }.
  # Nil for the first one and after a currency change (no like-for-like comparison).
  def self.change_percents(revisions)
    previous = nil
    revisions.sort_by(&:effective_on).to_h do |revision|
      comparable = previous && previous.currency_code == revision.currency_code
      change = ((revision.amount - previous.amount) / previous.amount * 100).round(2, BigDecimal::ROUND_HALF_UP) if comparable
      previous = revision
      [ revision.id, change ]
    end
  end

  # A raise scheduled before someone resigned stays in the history but never takes effect.
  def never_applied?
    employee.terminated_on.present? && effective_on > employee.terminated_on
  end

  private
    def effective_within_employment
      return if effective_on.nil? || employee.nil?

      if effective_on < employee.joined_on
        errors.add(:effective_on, "can't be before the join date (#{employee.joined_on.iso8601})")
      elsif employee.terminated_on && effective_on > employee.terminated_on
        errors.add(:effective_on, "can't be after the last working day (#{employee.terminated_on.iso8601})")
      end
    end
end
