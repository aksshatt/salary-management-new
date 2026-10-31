class Employee < ApplicationRecord
  include Auditable
  audit_masked bank_account_number: :mask_bank_account

  belongs_to :country
  has_many :salary_revisions

  scope :active, -> {
    today = Date.current
    where(joined_on: ..today).where("terminated_on IS NULL OR terminated_on >= ?", today)
  }

  scope :upcoming, -> { where("joined_on > ?", Date.current) }
  scope :terminated, -> { where("terminated_on < ?", Date.current) }

  # Part of the name or code, ignoring case; % and _ are plain characters.
  scope :search, ->(text) {
    pattern = "%#{sanitize_sql_like(text.to_s.strip)}%"
    where("employees.name ILIKE :q OR employees.code ILIKE :q", q: pattern)
  }

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :bank_account_number, with: ->(number) { number.gsub(/\s+/, "").upcase }

  validates :email, uniqueness: true
  validates :name, :email, :department, :job_title, :joined_on, :bank_account_number, presence: true
  validates :bank_account_number, format: { with: /\A[A-Z0-9]{6,34}\z/, message: "must be 6 to 34 letters or digits" },
    allow_blank: true
  validate :terminated_on_not_before_joined_on
  validate :joined_on_unchanged, on: :update
  validate :terminated_on_unchanged, on: :update
  validate :terminated_on_not_in_locked_payroll_month, if: :terminated_on_changed?

  def status
    today = Date.current
    if joined_on > today then "upcoming"
    elsif terminated_on && terminated_on < today then "terminated"
    else "active"
    end
  end

  # The salary in effect today, or on the last working day for someone who left.
  def current_revision
    as_of = [ Date.current, terminated_on ].compact.min
    salary_revisions.where(effective_on: ..as_of).order(:effective_on).last
  end

  def terminate(on:)
    self.terminated_on = on
    errors.add(:terminated_on, :blank) if on.blank?
    errors.empty? && save
  end

  # Only the payroll export may show the full number.
  def self.mask_bank_account(number)
    "••••#{number.length > 4 ? number.last(4) : ''}"
  end

  def masked_bank_account
    self.class.mask_bank_account(bank_account_number)
  end

  private
    def terminated_on_not_before_joined_on
      return if terminated_on.blank? || joined_on.blank? || terminated_on >= joined_on

      errors.add(:terminated_on, "can't be before the join date")
    end

    # The first salary revision is dated on the join date and can't change.
    def joined_on_unchanged
      errors.add(:joined_on, "can't be changed") if joined_on_changed?
    end

    # Termination can't be undone and its date can't be changed.
    def terminated_on_unchanged
      errors.add(:terminated_on, "already terminated") if terminated_on_changed? && terminated_on_was.present?
    end

    # A month that was already paid can't be changed by a termination in it.
    def terminated_on_not_in_locked_payroll_month
      return if terminated_on.nil?

      run = PayrollRun.find_by(month: terminated_on.beginning_of_month)
      return if run.nil? || run.open?

      errors.add(:terminated_on, "falls in a locked payroll month (#{run.month.strftime('%Y-%m')})")
    end
end
