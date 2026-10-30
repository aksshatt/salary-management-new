class Employee < ApplicationRecord
  belongs_to :country
  has_many :salary_revisions

  scope :active, -> {
    today = Date.current
    where(joined_on: ..today).where("terminated_on IS NULL OR terminated_on >= ?", today)
  }

  scope :upcoming, -> { where("joined_on > ?", Date.current) }
  scope :terminated, -> { where("terminated_on < ?", Date.current) }

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, uniqueness: true
  validates :name, :email, :department, :job_title, :joined_on, :bank_account_number, presence: true
  validate :terminated_on_not_before_joined_on

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

  # Only the payroll export may show the full number.
  def masked_bank_account
    visible = bank_account_number.length > 4 ? bank_account_number.last(4) : ""
    "••••#{visible}"
  end

  private
    def terminated_on_not_before_joined_on
      return if terminated_on.blank? || joined_on.blank? || terminated_on >= joined_on

      errors.add(:terminated_on, "can't be before the join date")
    end
end
