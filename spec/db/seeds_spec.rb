require "rails_helper"

RSpec.describe "db/seeds.rb" do
  def run_seeds(env)
    stub_const("ENV", ENV.to_h.merge("SEED_EMPLOYEES" => "50").merge(env))
    expect { load Rails.root.join("db/seeds.rb") }.to output.to_stdout
  end

  it "creates the HR user from HR_EMAIL and HR_PASSWORD" do
    run_seeds("HR_EMAIL" => "hr@acme.test", "HR_PASSWORD" => "seed-pass-123")

    expect(User.find_by(email_address: "hr@acme.test")&.authenticate("seed-pass-123")).to be_truthy
  end

  it "can run again, updating the password without duplicating the user" do
    run_seeds("HR_EMAIL" => "hr@acme.test", "HR_PASSWORD" => "old-pass-123")
    run_seeds("HR_EMAIL" => "hr@acme.test", "HR_PASSWORD" => "new-pass-456")

    expect(User.count).to eq(1)
    expect(User.first.authenticate("new-pass-456")).to be_truthy
  end

  it "skips the HR user when the credentials are not set" do
    stub_const("ENV", ENV.to_h.except("HR_EMAIL", "HR_PASSWORD"))

    expect { load Rails.root.join("db/seeds.rb") }.to output(/Skipping HR user: set HR_EMAIL and HR_PASSWORD/).to_stdout
    expect(User.count).to eq(0)
  end

  it "creates the countries with their currencies once" do
    2.times { run_seeds({}) }

    expect(Country.order(:name).pluck(:name, :currency_code)).to eq(
      [ [ "Brazil", "BRL" ], [ "Canada", "CAD" ], [ "Germany", "EUR" ], [ "India", "INR" ], [ "Singapore", "SGD" ],
        [ "United Kingdom", "GBP" ], [ "United States", "USD" ] ]
    )
  end

  it "creates the same 50 sample employees every time, only once" do
    run_seeds({})
    first_run = Employee.order(:id).pluck(:name, :department, :job_title, :joined_on)
    first_salaries = SalaryRevision.order(:id).pluck(:effective_on, :amount, :reason)
    run_seeds({})

    expect(Employee.count).to eq(50)

    SalaryRevision.delete_all
    Employee.delete_all
    run_seeds({})
    expect(Employee.order(:id).pluck(:name, :department, :job_title, :joined_on)).to eq(first_run)
    expect(SalaryRevision.order(:id).pluck(:effective_on, :amount, :reason)).to eq(first_salaries)
  end

  it "creates SEED_EMPLOYEES sample employees (10,000 by default) using the sample data generator" do
    generator = instance_double(Employees::SampleData, call: nil)
    allow(Employees::SampleData).to receive(:new).and_return(generator)

    run_seeds("SEED_EMPLOYEES" => nil)

    expect(Employees::SampleData).to have_received(:new).with(count: 10_000, today: Date.current, seed: 42)
  end

  it "creates an exchange rate for every country's currency, with USD at 1" do
    run_seeds({})

    rates = ExchangeRate.pluck(:currency_code, :units_per_usd).to_h
    expect(rates.keys).to match_array(Country.distinct.pluck(:currency_code))
    expect(rates["USD"]).to eq(1)
  end
end
