# encoding: utf-8
require 'spec_helper'

describe LoanEligibilityCheck do
  let(:loan_eligibility_check) { FactoryGirl.build(:loan_eligibility_check) }

  describe 'validations' do
    it 'has a valid factory' do
      expect(loan_eligibility_check).to be_valid
    end

    %w(
      amount
      repayment_duration
      lending_limit_id
      turnover
      trading_date
      sic_code
      loan_category_id
      reason_id
    ).each do |attr|
      it "is invalid without #{attr}" do
        loan_eligibility_check.send("#{attr}=", '')
        expect(loan_eligibility_check).not_to be_valid
      end
    end

    %w(
      viable_proposition
      would_you_lend
      collateral_exhausted
      not_insolvent
      previous_borrowing
      private_residence_charge_required
      personal_guarantee_required
    ).each do |attr|
      describe "boolean value: #{attr}" do
        it "is valid with true" do
          loan_eligibility_check.send("#{attr}=", true)
          expect(loan_eligibility_check).to be_valid
        end

        it "is valid with false" do
          loan_eligibility_check.send("#{attr}=", false)
          expect(loan_eligibility_check).to be_valid
        end

        it "is invalid with nil" do
          loan_eligibility_check.send("#{attr}=", nil)
          expect(loan_eligibility_check).to be_invalid
        end
      end
    end

    describe '#amount' do
      it 'is invalid when less than zero' do
        loan_eligibility_check.amount = -1
        expect(loan_eligibility_check).to be_invalid
      end

      it 'is invalid when zero' do
        loan_eligibility_check.amount = 0
        expect(loan_eligibility_check).to be_invalid
      end
    end

    describe '#loan_scheme' do
      it 'is invalid when not "E"' do
        loan_eligibility_check.loan_scheme = Loan::SFLG_SCHEME
        expect(loan_eligibility_check).to be_invalid
      end

      it 'is valid when "E"' do
        loan_eligibility_check.loan_scheme = Loan::EFG_SCHEME
        expect(loan_eligibility_check).to be_valid
      end
    end

    describe '#loan_source' do
      it 'is invalid when not "S"' do
        loan_eligibility_check.loan_source = Loan::LEGACY_SFLG_SOURCE
        expect(loan_eligibility_check).to be_invalid
      end

      it 'is valid when "S"' do
        loan_eligibility_check.loan_source = Loan::SFLG_SOURCE
        expect(loan_eligibility_check).to be_valid
      end
    end

    describe "#turnover" do
      it "is invalid when greater than £41,000,000" do
        loan_eligibility_check.turnover = Money.new(41_000_000_01)
        expect(loan_eligibility_check).not_to be_valid
      end
    end

    describe "#sic_code" do
      it "is invalid when blank" do
        loan_eligibility_check.sic_code = ''
        expect(loan_eligibility_check).not_to be_valid
      end
    end
  end

  describe '#lending_limit_id=' do
    let(:lender) { loan_eligibility_check.loan.lender }

    it 'blows up if attempting to set a LendingLimit belonging to another Lender' do
      another_lending_limit = FactoryGirl.create(:lending_limit)

      expect {
        loan_eligibility_check.lending_limit_id = another_lending_limit.id
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'blows up when attempting to set an inactive LendingLimit' do
      another_lending_limit = FactoryGirl.create(:lending_limit, active: false, lender: lender)

      expect {
        loan_eligibility_check.lending_limit_id = another_lending_limit.id
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#save' do
    let(:validator) { double(validate: nil) }

    before do
      loan_eligibility_check.stub(:eligibility_validator).and_return(validator)
    end

    context 'when there are *no* eligibility errors' do
      before do
        loan_eligibility_check.stub(:ineligibility_reasons).and_return([])
      end

      it 'sets the state to Eligible' do
        loan_eligibility_check.save
        expect(loan_eligibility_check.loan.state).to eq(Loan::Eligible)
      end

      it 'creates an accepted loan state change' do
        expect {
          loan_eligibility_check.save
        }.to change(LoanStateChange, :count).by(1)

        expect(LoanStateChange.last!.event).to eq(LoanEvent::Accept)
      end
    end

    context 'when there *are* eligibility errors' do
      before do
        loan_eligibility_check.stub(:ineligibility_reasons).and_return(['Reason 1', 'Reason 2'])
      end

      it "should set the state to Rejected if its not eligible" do
        loan_eligibility_check.save
        expect(loan_eligibility_check.loan.state).to eq(Loan::Rejected)
      end

      it "should create rejected loan state change if its not eligible" do
        expect {
          loan_eligibility_check.save
        }.to change(LoanStateChange, :count).by(1)

        expect(LoanStateChange.last!.event).to eq(LoanEvent::Reject)
      end

      it "should create loan ineligibility record if its not eligible" do
        expect {
          loan_eligibility_check.save
        }.to change(LoanIneligibilityReason, :count).by(1)

        expect(LoanIneligibilityReason.last!.reason).to eq("Reason 1\nReason 2")
      end
    end

    context 'phase 5' do
      let(:lender) { FactoryGirl.create(:lender) }
      let(:lending_limit) { FactoryGirl.create(:lending_limit, :phase_5, lender: lender) }

      before do
        loan_eligibility_check.loan.lending_limit = lending_limit
      end

      context 'when amount is greater than £1M' do
        it "is rejected" do
          loan_eligibility_check.amount = Money.new(1_000_000_01)
          loan_eligibility_check.save
          expect(loan_eligibility_check.loan.state).to eq(Loan::Rejected)
        end
      end
    end

    context 'phase 6' do
      let(:lender) { FactoryGirl.create(:lender) }
      let(:lending_limit) { FactoryGirl.create(:lending_limit, :phase_6, lender: lender) }

      before do
        loan_eligibility_check.loan.lending_limit = lending_limit
      end

      context 'when amount is greater than £600k and loan term is longer than 5 years' do
        it "is rejected" do
          loan_eligibility_check.amount = Money.new(600_000_01)
          loan_eligibility_check.repayment_duration = 61
          loan_eligibility_check.save
          expect(loan_eligibility_check.loan.state).to eq(Loan::Rejected)
        end
      end

      context 'when amount is greater £1.2M' do
        it "is rejected" do
          loan_eligibility_check.amount = Money.new(1_200_000_01)
          loan_eligibility_check.save
          expect(loan_eligibility_check.loan.state).to eq(Loan::Rejected)
        end
      end
    end
  end

  describe "#sic_code=" do
    let(:sic_code) { FactoryGirl.create(:sic_code, description: 'My SIC description', eligible: false) }

    it "should cache SIC code, description and eligibility on the loan" do
      loan_eligibility_check.loan.sic_desc = nil
      loan_eligibility_check.loan.sic_eligible = nil

      loan_eligibility_check.sic_code = sic_code.code

      expect(loan_eligibility_check.loan.sic_code).to eq(sic_code.code)
      expect(loan_eligibility_check.loan.sic_desc).to eq(sic_code.description)
      expect(loan_eligibility_check.loan.sic_eligible).to eq(sic_code.eligible)
    end

    it "should not cache SIC data when specified code is blank" do
      loan_eligibility_check.loan.sic_desc = nil
      loan_eligibility_check.loan.sic_eligible = nil

      loan_eligibility_check.sic_code = ""

      expect(loan_eligibility_check.loan.sic_code).to be_nil
      expect(loan_eligibility_check.loan.sic_desc).to be_nil
      expect(loan_eligibility_check.loan.sic_eligible).to be_nil
    end

    it "should blow up when trying to assign inactive SIC code" do
      sic_code.update_attribute(:active, false)
      loan_eligibility_check.loan.sic_desc = nil
      loan_eligibility_check.loan.sic_eligible = nil

      expect {
        loan_eligibility_check.sic_code = sic_code.code
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect(loan_eligibility_check.loan.sic_code).to be_nil
      expect(loan_eligibility_check.loan.sic_desc).to be_nil
      expect(loan_eligibility_check.loan.sic_eligible).to be_nil
    end
  end
end
