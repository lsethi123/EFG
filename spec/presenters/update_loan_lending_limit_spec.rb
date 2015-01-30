require 'spec_helper'

describe UpdateLoanLendingLimit do
  describe "validations" do
    subject { FactoryGirl.build(:update_loan_lending_limit) }

    it "has a valid factory" do
      expect(subject).to be_valid
    end

    it "requries a new_lending_limit_id" do
      subject.new_lending_limit_id = ''
      expect(subject).not_to be_valid
    end
  end

  describe "#save" do
    let(:lender) { FactoryGirl.create(:lender) }
    let!(:lending_limit1) { FactoryGirl.create(:lending_limit, name: 'Lending Limit #1', lender: lender) }
    let!(:lending_limit2) { FactoryGirl.create(:lending_limit, :phase_6, name: 'Lending Limit #2', lender: lender) }
    let!(:loan) { FactoryGirl.create(:loan, :completed, lender: lender, lending_limit: lending_limit1, loan_category_id: LoanCategory::TypeF.id) }
    let!(:premium_schedule) { FactoryGirl.create(:premium_schedule, loan: loan) }
    let(:presenter) do
      UpdateLoanLendingLimit.new(loan).tap do |presenter|
        presenter.new_lending_limit_id = lending_limit2.id.to_s
      end
    end

    it "changes the lending limit on the loan" do
      presenter.new_lending_limit_id = lending_limit2.id.to_s
      presenter.save

      loan.reload
      expect(loan.lending_limit).to eq(lending_limit2)
    end

    it "stores the previous state aid figure" do
      previous_state_aid = loan.state_aid
      presenter.save

      expect(presenter.previous_state_aid).to eq(previous_state_aid)
    end

    it "stores the new state aid figure" do
      presenter.save
      expect(presenter.new_state_aid).to eq(Money.new(794_98, 'EUR'))
    end

    context "when the loan is not valid for a Phase 5 lending limit" do
      let!(:lending_limit2) { FactoryGirl.create(:lending_limit, :phase_5, lender: lender) }

      let!(:loan) { FactoryGirl.create(:loan, :completed, lender: lender, lending_limit: lending_limit1, amount: Money.new(1_000_000_01)) }

      it "changes the state of the loan to incomplete" do
        presenter.save
        expect(loan.state).to eq(Loan::Incomplete)
      end
    end

    context "when the loan is not valid for a Phase 6 lending limit" do
      let!(:lending_limit2) { FactoryGirl.create(:lending_limit, :phase_6, lender: lender) }

      let!(:loan) { FactoryGirl.create(:loan, :completed, lender: lender, lending_limit: lending_limit1, amount: Money.new(600_000_01), repayment_duration: 61) }

      it "changes the state of the loan to incomplete" do
        presenter.save
        expect(loan.state).to eq(Loan::Incomplete)
      end
    end
  end
end
