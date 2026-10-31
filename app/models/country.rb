class Country < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :currency_code, format: { with: /\A[A-Z]{3}\z/ }
  validates :tax_rate_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, decimal_places: 2
  validate :currency_has_exchange_rate

  private
    def currency_has_exchange_rate
      return if currency_code.blank? || ExchangeRate.exists?(currency_code:)

      errors.add(:currency_code, "has no exchange rate")
    end
end
