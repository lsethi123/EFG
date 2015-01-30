require 'spec_helper'

describe EligibilityDecisionEmail do

  describe "validations" do
    let(:eligibility_decision_email) { FactoryGirl.build(:eligibility_decision_email) }

    it "should have a valid factory" do
      expect(eligibility_decision_email).to be_valid
    end

    it "must have an email" do
      eligibility_decision_email.email = nil
      expect(eligibility_decision_email).not_to be_valid
    end

    it "must have a valid email address" do
      eligibility_decision_email.email = "wrong"
      expect(eligibility_decision_email).not_to be_valid
      eligibility_decision_email.email = "wrong@wrong"
      expect(eligibility_decision_email).not_to be_valid
      eligibility_decision_email.email = "@wrong.com"
      expect(eligibility_decision_email).not_to be_valid
      eligibility_decision_email.email = "wr ong@wrong.com"
      expect(eligibility_decision_email).not_to be_valid
      eligibility_decision_email.email = "right@right.com"
      expect(eligibility_decision_email).to be_valid
    end

    it "must have a loan" do
      eligibility_decision_email.loan = nil
      expect(eligibility_decision_email).not_to be_valid
    end
  end

  describe "#deliver_email" do
    context 'with eligible loan' do
      let(:eligibility_decision_email) { FactoryGirl.build(:eligibility_decision_email) }

      it "should send email" do
        expect {
          eligibility_decision_email.deliver_email
        }.to change(ActionMailer::Base.deliveries, :count).by(1)
      end
    end

    context 'with ineligible loan' do
      let(:eligibility_decision_email) { FactoryGirl.build(:ineligible_eligibility_decision_email) }

      it "should send email" do
        expect {
          eligibility_decision_email.deliver_email
        }.to change(ActionMailer::Base.deliveries, :count).by(1)
      end
    end
  end

end
