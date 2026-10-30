require "rails_helper"

RSpec.describe ReportMonth do
  around { |example| travel_to(Date.new(2026, 10, 15)) { example.run } }

  it "is as of the last day of a past month" do
    expect(described_class.parse("2026-09").as_of).to eq(Date.new(2026, 9, 30))
  end

  it "is as of today for the current month" do
    expect(described_class.parse("2026-10").as_of).to eq(Date.new(2026, 10, 15))
  end

  it "ends February on the 29th in a leap year" do
    expect(described_class.parse("2024-02").as_of).to eq(Date.new(2024, 2, 29))
  end

  it "rejects future months and anything that isn't YYYY-MM" do
    %w[2026-11 2026-13 2026-1 abc].push("", nil).each do |value|
      expect { described_class.parse(value) }.to raise_error(ReportMonth::Invalid), "expected #{value.inspect} to be rejected"
    end
  end

  it "defaults to the previous month" do
    expect(described_class.default.as_of).to eq(Date.new(2026, 9, 30))
  end
end
