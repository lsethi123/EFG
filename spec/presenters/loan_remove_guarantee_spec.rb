require 'spec_helper'

describe LoanRemoveGuarantee do

  describe 'validations' do
    let(:loan_remove_guarantee) { FactoryGirl.build(:loan_remove_guarantee) }

    let(:loan) { loan_remove_guarantee.loan }

    before(:each) do
      loan.save!
      FactoryGirl.create(:initial_draw_change, amount_drawn: loan.amount, loan: loan)
    end

    it 'should have a valid factory' do
      expect(loan_remove_guarantee).to be_valid
    end

    it 'should be invalid without remove guarantee on' do
      loan_remove_guarantee.remove_guarantee_on = nil
      expect(loan_remove_guarantee).not_to be_valid
    end

    it 'should be invalid without remove guarantee outstanding amount' do
      loan_remove_guarantee.remove_guarantee_outstanding_amount = nil
      expect(loan_remove_guarantee).not_to be_valid
    end

    it 'should be invalid without a cancelled date' do
      loan_remove_guarantee.remove_guarantee_reason = nil
      expect(loan_remove_guarantee).not_to be_valid
    end

    it "should be invalid when remove guarantee outstanding amount is greater than total amount drawn" do
      loan_remove_guarantee.remove_guarantee_outstanding_amount = loan.amount + Money.new(1_00)
      expect(loan_remove_guarantee).not_to be_valid

      loan_remove_guarantee.remove_guarantee_outstanding_amount = loan.amount
      expect(loan_remove_guarantee).to be_valid
    end

    it "should be invalid when remove guarantee date is before initial draw date" do
      loan_remove_guarantee.remove_guarantee_on = loan.initial_draw_change.date_of_change - 1.day
      expect(loan_remove_guarantee).not_to be_valid

      loan_remove_guarantee.remove_guarantee_on = loan.initial_draw_change.date_of_change
      expect(loan_remove_guarantee).to be_valid
    end
  end

end
