require 'spec_helper'

describe UserMailer do

  describe "#new_account_notification" do
    let(:user) { FactoryGirl.build(:lender_user, first_name: 'Joe', username: 'joe123') }
    let(:token) { 'jKMpsc7CC_1ABh1rDUBq' }
    let(:mail) { UserMailer.new_account_notification(user, token) }

    it "should be set to be delivered to the user's email address" do
      expect(mail.to).to eq([user.email])
    end

    it "should contain user's first name" do
      expect(mail.body).to include('joe')
    end

    it "should contain user's username" do
      expect(mail.body).to include('joe123')
    end

    it "should contain link to reset password page" do
      expect(mail.body).to include("?reset_password_token=#{user.reset_password_token}")
    end

    it "should contain a link back to the home page to resend the request" do
      expect(mail.body).to include(root_url)
    end

    it "should have a from header" do
      expect(Devise.mailer_sender).to match mail.from[0]
    end
  end

end
