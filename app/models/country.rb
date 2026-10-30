class Country < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :currency_code, format: { with: /\A[A-Z]{3}\z/ }
  validate :currency_has_exchange_rate

  private
    def currency_has_exchange_rate
      return if currency_code.blank? || ExchangeRate.exists?(currency_code:)

      errors.add(:currency_code, "has no exchange rate")
    end
end
