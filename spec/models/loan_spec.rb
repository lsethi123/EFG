require 'spec_helper'

describe Loan do
  describe 'validations' do
    let(:loan) { FactoryGirl.build(:loan) }

    it 'has a valid Factory' do
      loan.should be_valid
    end

    it 'requires a lender' do
      expect {
        loan.lender = nil
        loan.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    %w(
      amount
      lender_cap_id
      repayment_duration
      turnover
      trading_date
      sic_code
      loan_category_id
      reason_id
    ).each do |attr|
      it "is invalid without #{attr}" do
        loan[attr] = ''
        loan.should_not be_valid
      end
    end

    %w(
      viable_proposition
      would_you_lend
      collateral_exhausted
      previous_borrowing
      private_residence_charge_required
      personal_guarantee_required
    ).each do |attr|
      describe "boolean value: #{attr}" do
        it "is valid with true" do
          loan[attr] = true
          loan.should be_valid
        end

        it "is valid with false" do
          loan[attr] = false
          loan.should be_valid
        end

        it "is invalid with nil" do
          loan[attr] = nil
          loan.should be_invalid
        end
      end
    end

    describe 'repayment_duration' do
      it 'is invalid when zero' do
        loan[:repayment_duration] = 0
        loan.should be_invalid
      end

      it 'is valid when greater than zero' do
        loan[:repayment_duration] = 1
        loan.should be_valid
      end
    end
  end

  describe '#amount / #amount=' do
    let(:loan) { Loan.new }

    it 'is formatted with pence' do
      loan[:amount] = 12345
      loan.amount.to_s.should == '123.45'
    end

    it 'is stored as an integer' do
      loan.amount = '123.45'
      loan[:amount].should == 12345
    end

    it 'is stored as nil for a nil value' do
      loan[:amount] = 12345
      loan.amount = nil
      loan.amount.should be_nil
    end

    it 'is stored as nil for a blank value' do
      loan[:amount] = 12345
      loan.amount = ''
      loan.amount.should be_nil
    end
  end

  describe '#repayment_duration / #repayment_duration=' do
    let(:loan) { Loan.new }

    it 'conforms to the MonthDuration interface' do
      loan[:repayment_duration] = 18
      loan.repayment_duration.should == MonthDuration.new(18)
    end

    it 'converts year/months hash to months' do
      loan.repayment_duration = { years: 1, months: 6 }
      loan.repayment_duration.should == MonthDuration.new(18)
    end

    it 'does not convert blank values to zero' do
      loan.repayment_duration = { years: '', months: '' }
      loan.repayment_duration.should be_nil
    end
  end

  describe '#turnover / #turnover=' do
    let(:loan) { Loan.new }

    it 'is formatted with pence' do
      loan[:turnover] = 12345
      loan.turnover.to_s.should == '123.45'
    end

    it 'is stored as an integer' do
      loan.turnover = '123.45'
      loan[:turnover].should == 12345
    end

    it 'is stored as nil for a nil value' do
      loan[:turnover] = 12345
      loan.turnover = nil
      loan.turnover.should be_nil
    end

    it 'is stored as nil for a blank value' do
      loan[:turnover] = 12345
      loan.turnover = ''
      loan.turnover.should be_nil
    end
  end
end
