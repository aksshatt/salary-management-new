require "rails_helper"

RSpec.describe Employees::SampleData do
  let(:today) { Date.new(2026, 10, 15) }

  before do
    { "India" => [ "INR", "83.25" ], "Germany" => [ "EUR", "0.92" ], "United States" => [ "USD", "1" ] }.each do |name, (code, rate)|
      create(:exchange_rate, currency_code: code, units_per_usd: rate) unless ExchangeRate.exists?(currency_code: code)
      create(:country, name:, currency_code: code)
    end
  end

  def generate(count: 200, seed: 42)
    described_class.new(count:, today:, seed:).call
  end

  it "creates the employees, each with an initial salary on their join date in their country's currency" do
    generate

    expect(Employee.count).to eq(200)
    initials = SalaryRevision.where(reason: "initial").includes(employee: :country)
    expect(initials.size).to eq(200)
    expect(initials.all? { |r| r.effective_on == r.employee.joined_on && r.currency_code == r.employee.country.currency_code }).to be(true)
  end

  it "only creates records the app itself would accept" do
    generate

    invalid = (Employee.includes(:country).to_a + SalaryRevision.includes(employee: :country).to_a).reject(&:valid?)
    expect(invalid.map { |record| [ record.class.name, record.errors.full_messages ] }).to eq([])
  end

  it "creates the same data for the same seed and different data for another seed" do
    snapshot = -> { [ Employee.order(:email).pluck(:email, :joined_on, :department), SalaryRevision.order(:amount).pluck(:amount) ] }
    generate(seed: 7)
    first = snapshot.call
    SalaryRevision.delete_all
    Employee.delete_all
    generate(seed: 7)
    same = snapshot.call
    SalaryRevision.delete_all
    Employee.delete_all
    generate(seed: 8)

    expect(same).to eq(first)
    expect(snapshot.call).not_to eq(first)
  end

  it "spreads people over several departments and career levels, with senior roles paid more" do
    generate(count: 1_000)

    expect(Employee.distinct.count(:department)).to be >= 6
    expect(Employee.distinct.count(:job_title)).to be >= 20
    usd = ->(title_pattern) do
      SalaryRevision.where(reason: "initial").joins(:employee).where("employees.job_title LIKE ?", title_pattern)
        .map { |r| ExchangeRate.to_usd(r.amount, r.currency_code) }.sort.then { |a| a[a.size / 2] }
    end
    expect(usd.call("Senior %")).to be > usd.call("Junior %")
  end

  it "has active, upcoming and departed employees, with joiners and leavers in each of the last 12 months" do
    generate(count: 1_000)

    travel_to(today) do
      expect(Employee.terminated.count).to be_between(80, 180)
      expect(Employee.upcoming.count).to be_between(1, 40)
      expect(Employee.active.count).to be > 750
    end
    months = (0..11).map { |i| (today - i.months).beginning_of_month }
    expect(months.map { |m| Employee.where(joined_on: m..m.end_of_month).exists? }).to all(be(true))
    expect(months.map { |m| Employee.where(terminated_on: m..m.end_of_month).exists? }).to all(be(true))
  end

  it "gives long-serving people a salary history of raises and promotions, never after they left" do
    generate(count: 1_000)

    reasons = SalaryRevision.group(:reason).count
    expect(reasons.keys).to include("increment", "promotion", "correction")
    expect(SalaryRevision.count).to be > 2_000
    expect(SalaryRevision.where("effective_on > ?", today).exists?).to be(true)
    expect(SalaryRevision.joins(:employee).where("salary_revisions.effective_on > employees.terminated_on").exists?).to be(false)

    histories = SalaryRevision.where.not(reason: "correction").order(:effective_on).group_by(&:employee_id).values
    expect(histories.all? { |revisions| revisions.each_cons(2).all? { |a, b| b.amount > a.amount } }).to be(true)
  end
end
