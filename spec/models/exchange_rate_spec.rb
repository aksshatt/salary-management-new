require "rails_helper"

RSpec.describe ExchangeRate do
  it "converts an amount to USD, rounded half up to the cent" do
    create(:exchange_rate, currency_code: "INR", units_per_usd: "83.25")

    expect(described_class.to_usd(BigDecimal("1320000.50"), "INR")).to eq(BigDecimal("15855.86"))
  end

  it "rounds half up at exactly half a cent" do
    create(:exchange_rate, currency_code: "EUR", units_per_usd: "2")

    expect(described_class.to_usd(BigDecimal("0.05"), "EUR")).to eq(BigDecimal("0.03"))
  end

  it "raises a clear error for a currency without a rate" do
    expect { described_class.to_usd(BigDecimal("10"), "JPY") }.to raise_error(ActiveRecord::RecordNotFound, /JPY/)
  end

  it "requires a three-letter uppercase currency code and a rate above 0" do
    expect(build(:exchange_rate)).to be_valid
    [ { currency_code: "inr" }, { currency_code: "IN" }, { units_per_usd: 0 }, { units_per_usd: -1 }, { units_per_usd: nil } ]
      .each { |attrs| expect(build(:exchange_rate, **attrs)).not_to be_valid, "expected #{attrs} to be rejected" }
  end

  it "enforces the rules in the database" do
    create(:exchange_rate, currency_code: "INR")

    expect { build(:exchange_rate, currency_code: "INR").save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    expect { build(:exchange_rate, currency_code: "EUR", units_per_usd: 0).save(validate: false) }
      .to raise_error(ActiveRecord::StatementInvalid, /exchange_rates_positive/)
    expect { build(:exchange_rate, currency_code: nil).save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
  end

  it "keeps USD at exactly 1" do
    expect(build(:exchange_rate, currency_code: "USD", units_per_usd: 1)).to be_valid

    usd = build(:exchange_rate, currency_code: "USD", units_per_usd: "1.1")
    expect(usd).not_to be_valid
    expect(usd.errors[:units_per_usd]).to include("must be 1 for USD")
  end
end
