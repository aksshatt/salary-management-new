require "rails_helper"

RSpec.describe "db/seeds.rb" do
  def run_seeds(env)
    stub_const("ENV", ENV.to_h.merge(env))
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
end
