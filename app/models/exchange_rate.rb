# How many units of a currency make 1 USD (e.g. INR 83.25). Used only to
# compare pay across countries; salaries stay in local currency.
class ExchangeRate < ApplicationRecord
  validates :currency_code, format: { with: /\A[A-Z]{3}\z/ }, uniqueness: true
  validates :units_per_usd, numericality: { greater_than: 0 }
  validate :usd_is_one

  # Nil when the currency has no rate, so a missing rate never hides the salary.
  def self.usd_or_nil(amount, currency_code)
    to_usd(amount, currency_code)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def self.to_usd(amount, currency_code)
    rate = find_by(currency_code:) or raise ActiveRecord::RecordNotFound, "No exchange rate for #{currency_code}"
    (amount / rate.units_per_usd).round(2, BigDecimal::ROUND_HALF_UP)
  end

  private
    def usd_is_one
      errors.add(:units_per_usd, "must be 1 for USD") if currency_code == "USD" && units_per_usd != 1
    end
end
