class Country < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :currency_code, format: { with: /\A[A-Z]{3}\z/ }
end
