require 'spec_helper'

describe 'Claim Limit Phase 6' do

  let(:lender) { FactoryGirl.create(:lender) }

  let(:lending_limit1) { FactoryGirl.create(:lending_limit, :phase_6, lender: lender) }

  let(:lending_limit2) { FactoryGirl.create(:lending_limit, :phase_6, lender: lender) }

  let(:loan_amount) { Money.new(50_000_00) }

  let!(:guaranteed_loan) { FactoryGirl.create(:loan, :guaranteed, lender: lender, lending_limit: lending_limit1, amount: loan_amount, loan_category_id: 6) }
  let!(:lender_demand_loan) { FactoryGirl.create(:loan, :guaranteed, :lender_demand, lender: lender, lending_limit: lending_limit1, amount: loan_amount, loan_category_id: 8) }
  let!(:demanded_loan) { FactoryGirl.create(:loan, :guaranteed, :demanded, lender: lender, lending_limit: lending_limit1, amount: loan_amount) }
  let!(:settled_loan) { FactoryGirl.create(:loan, :guaranteed, :settled, lender: lender, lending_limit: lending_limit2, amount: loan_amount) }
  let!(:recovered_loan) { FactoryGirl.create(:loan, :guaranteed, :recovered, lender: lender, lending_limit: lending_limit2, amount: loan_amount) }
  let!(:realised_loan) { FactoryGirl.create(:loan, :guaranteed, :realised, lender: lender, lending_limit: lending_limit2, amount: loan_amount) }
  let!(:excluded_loan) { FactoryGirl.create(:loan, :offered, lender: lender, lending_limit: lending_limit2, amount: loan_amount) }

  let!(:pre_claim_realisation) { FactoryGirl.create(:loan_realisation, :pre, realised_loan: settled_loan, realised_amount: Money.new(1_000_00)) }
  let!(:post_claim_realisation) { FactoryGirl.create(:loan_realisation, :post, realised_loan: settled_loan, realised_amount: Money.new(1_000_00)) }

  let(:claim_limit) { Phase6ClaimLimitCalculator.new(lender) }

  before do
    [guaranteed_loan, lender_demand_loan, demanded_loan, settled_loan, recovered_loan, realised_loan].each do |loan|
      loan.initial_draw_change.update_attribute(:amount_drawn, loan_amount)
    end
  end

  describe "#total_amount" do
    it "returns the cumulative drawn amount (65% drawn amount for Type F & H loans) at 75% for first one hundred thousand and 15% for the remainder" do
      expect(claim_limit.total_amount).to eq(Money.new(99_750_00))
    end
  end

  describe "#amount_remaining" do
    # £99,750 (claim limit) + £1000 (total pre-claim realisations) - £9,375 (total settled amount)
    it "returns the claim limit amount + pre-claim limit realisations - total settled amount" do
      expect(claim_limit.amount_remaining).to eq(Money.new(91_375_00))
    end
  end

  describe "#percentage_remaining" do
    it "returns the percentage of remaining claim limit" do
      expect(claim_limit.percentage_remaining).to eq(92)
    end
  end

end
