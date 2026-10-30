require "rails_helper"

RSpec.describe Session do
  it "requires a user" do
    session = Session.new(user: nil)

    expect(session).not_to be_valid
    expect(session.errors[:user]).to include("must exist")
  end

  it "requires a user in the database" do
    expect { Session.new.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
  end
end
