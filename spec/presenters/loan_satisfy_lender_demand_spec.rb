require 'spec_helper'

describe LoanSatisfyLenderDemand do
  describe 'validations' do
    let(:presenter) { FactoryGirl.build(:loan_satisfy_lender_demand) }

    it 'has a valid factory' do
      expect(presenter).to be_valid
    end

    it 'requires a date_of_change' do
      presenter.date_of_change = nil
      expect(presenter).not_to be_valid
    end
  end

  describe '#save' do
    let(:user) { FactoryGirl.create(:lender_user) }
    let(:loan) { FactoryGirl.create(:loan, :lender_demand) }
    let(:presenter) { FactoryGirl.build(:loan_satisfy_lender_demand, loan: loan, modified_by: user) }

    it 'creates a LoanChange, a PremiumSchedule, and updates the loan' do
      expect(presenter.save).to eq(true)

      loan_change = loan.loan_changes.last!
      expect(loan_change.change_type).to eq(ChangeType::LenderDemandSatisfied)
      expect(loan_change.created_by).to eq(user)

      loan.reload
      expect(loan.state).to eq(Loan::Guaranteed)
      expect(loan.modified_by).to eq(user)
    end
  end
end
