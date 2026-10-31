require "rails_helper"

RSpec.describe Country do
  it "is valid with a name and currency code" do
    expect(build(:country, name: "India", currency_code: "INR")).to be_valid
  end

  it "requires a name" do
    expect(build(:country, name: "")).not_to be_valid
  end

  it "requires a three-letter uppercase currency code" do
    %w[US usd USDX].each do |code|
      expect(build(:country, currency_code: code)).not_to be_valid, "expected #{code.inspect} to be rejected"
    end
  end

  it "rejects a duplicate name" do
    create(:country, name: "India")

    expect(build(:country, name: "India")).not_to be_valid
  end

  it "enforces unique names in the database" do
    create(:country, name: "India")

    expect { build(:country, name: "India").save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "needs an exchange rate for its currency so its salaries can be compared" do
    country = Country.new(name: "Japan", currency_code: "JPY")

    expect(country).not_to be_valid
    expect(country.errors[:currency_code]).to include("has no exchange rate")
  end

  describe "tax rate" do
    it "accepts a percentage from 0 to 100" do
      expect([ build(:country, tax_rate_percent: 0), build(:country, tax_rate_percent: 100), build(:country, tax_rate_percent: "12.5") ])
        .to all(be_valid)
    end

    it "rejects a missing rate, one outside 0 to 100, or more than 2 decimals" do
      [ nil, "-0.01", "100.01" ].each do |rate|
        expect(build(:country, tax_rate_percent: rate)).not_to be_valid, "expected #{rate.inspect} to be rejected"
      end
      country = build(:country, tax_rate_percent: "12.345")
      expect(country).not_to be_valid
      expect(country.errors[:tax_rate_percent]).to include("can have at most 2 decimal places")
    end

    it "is required and kept between 0 and 100 by the database" do
      expect { build(:country, tax_rate_percent: nil).save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
      expect { build(:country, tax_rate_percent: 101).save(validate: false) }
        .to raise_error(ActiveRecord::StatementInvalid, /countries_tax_rate_range/)
    end
  end
end
