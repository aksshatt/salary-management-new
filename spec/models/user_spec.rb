require "rails_helper"

RSpec.describe User do
  it "is valid with an email address and password" do
    expect(build(:user)).to be_valid
  end

  it "requires an email address" do
    user = build(:user, email_address: "")

    expect(user).not_to be_valid
    expect(user.errors[:email_address]).to include("can't be blank")
  end

  it "requires a password" do
    user = build(:user, password: nil)

    expect(user).not_to be_valid
    expect(user.errors[:password]).to include("can't be blank")
  end

  it "normalizes the email address to lowercase without surrounding spaces" do
    user = build(:user, email_address: "  HR@Acme.Test ")

    expect(user.email_address).to eq("hr@acme.test")
  end

  it "rejects a duplicate email address regardless of case" do
    create(:user, email_address: "hr@acme.test")
    duplicate = build(:user, email_address: "HR@acme.test")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email_address]).to include("has already been taken")
  end

  it "enforces unique email addresses in the database" do
    create(:user, email_address: "hr@acme.test")
    duplicate = build(:user, email_address: "hr@acme.test")

    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "deletes its sessions when deleted" do
    user = create(:user)
    Session.create!(user: user)

    expect { user.destroy }.to change(Session, :count).by(-1)
  end
end
