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
end
