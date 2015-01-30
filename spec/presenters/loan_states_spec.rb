require 'spec_helper'

describe LoanStates do

  describe "#states" do
    let!(:lender) { FactoryGirl.create(:lender) }

    let(:loan_states) { LoanStates.new(lender).states }

    before(:each) do
      # guaranteed loans
      FactoryGirl.create(:loan, :guaranteed, :legacy_sflg, lender: lender)
      FactoryGirl.create(:loan, :guaranteed, :sflg, lender: lender)
      FactoryGirl.create(:loan, :guaranteed, lender: lender)

      # demanded loans
      FactoryGirl.create(:loan, :demanded, :legacy_sflg, lender: lender)
      FactoryGirl.create(:loan, :demanded, :legacy_sflg, lender: lender)
      FactoryGirl.create(:loan, :demanded, lender: lender)
      FactoryGirl.create(:loan, :demanded, lender: lender)
    end

    it "should return loans grouped by state" do
      expect(loan_states.size).to eq(2)
      expect(loan_states.first.state).to eq(Loan::Guaranteed)
      expect(loan_states.last.state).to eq(Loan::Demanded)
    end

    it "should have legacy sflg loan count" do
      expect(loan_states.first.legacy_sflg_loans_count).to eq(1)
      expect(loan_states.last.legacy_sflg_loans_count).to eq(2)
    end

    it "should have sflg loan count" do
      expect(loan_states.first.sflg_loans_count).to eq(1)
      expect(loan_states.last.sflg_loans_count).to eq(0)
    end

    it "should have efg loan count" do
      expect(loan_states.first.efg_loans_count).to eq(1)
      expect(loan_states.last.efg_loans_count).to eq(2)
    end

    it "should have total loans count" do
      expect(loan_states.first.total_loans).to eq(3)
      expect(loan_states.last.total_loans).to eq(4)
    end
  end

end
