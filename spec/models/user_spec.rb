require 'spec_helper'

describe User do
  it "requires passwords to be suitably strong" do
    user = FactoryGirl.build(:user, :password => "aaaaaa")
    expect(user.valid?).to eq(true)
    user.save!

    # REVIEW: slightly hokey - we don't validate the password for new records. Not sure if we want to revisit that?
    user.first_name = user.last_name
    expect(user.valid?).to eq(false)
    expect(user.errors[:password]).to eq([I18n.t('errors.messages.insufficient_entropy', entropy: 3, minimum_entropy: Devise::Models::Strengthened::MINIMUM_ENTROPY)])
  end
end