require 'spec_helper'

describe "Claim Limit Phase 1" do

  let(:lender) { FactoryGirl.create(:lender) }

  let(:lending_limit1) { FactoryGirl.create(:lending_limit, :phase_1, lender: lender) }

  let(:lending_limit2) { FactoryGirl.create(:lending_limit, :phase_1, lender: lender) }

  let(:loan_amount) { Money.new(50_000_00) }

  let!(:guaranteed_loan) { FactoryGirl.create(:loan, :guaranteed, lender: lender, lending_limit: lending_limit1, amount: loan_amount) }

  let!(:lender_demand_loan) { FactoryGirl.create(:loan, :guaranteed, :lender_demand, lender: lender, lending_limit: lending_limit1, amount: loan_amount) }

  let!(:demanded_loan) { FactoryGirl.create(:loan, :guaranteed, :demanded, lender: lender, lending_limit: lending_limit1, amount: loan_amount) }

  let!(:settled_loan) { FactoryGirl.create(:loan, :guaranteed, :settled, lender: lender, lending_limit: lending_limit2, amount: loan_amount) }

  let!(:recovered_loan) { FactoryGirl.create(:loan, :guaranteed, :recovered, lender: lender, lending_limit: lending_limit2, amount: loan_amount) }

  let!(:realised_loan) { FactoryGirl.create(:loan, :guaranteed, :realised, lender: lender, lending_limit: lending_limit2, amount: loan_amount) }

  let!(:excluded_loan) { FactoryGirl.create(:loan, :offered, lender: lender, lending_limit: lending_limit2, amount: loan_amount) }

  let!(:pre_claim_realisation) { FactoryGirl.create(:loan_realisation, :pre, realised_loan: settled_loan, realised_amount: Money.new(1_000_00)) }
  let!(:post_claim_realisation) { FactoryGirl.create(:loan_realisation, :post, realised_loan: settled_loan, realised_amount: Money.new(1_000_00)) }

  let(:claim_limit) { Phase1ClaimLimitCalculator.new(lender) }

  before do
    [lender_demand_loan, demanded_loan, settled_loan, recovered_loan, realised_loan].each do |loan|
      loan.initial_draw_change.update_attribute(:amount_drawn, loan_amount)
    end

    # agreed draw and reprofile draw loan changes should be included in calculation
    guaranteed_loan.initial_draw_change.update_attribute(:amount_drawn, Money.new(30_000_00))

    FactoryGirl.create(:loan_change, loan: guaranteed_loan, amount_drawn: Money.new(10_000_00))

    FactoryGirl.create(:loan_change, loan: guaranteed_loan, amount_drawn: Money.new(10_000_00), change_type: ChangeType::ReprofileDraws)
  end

  describe "#total_amount" do
    # £300,000 (6 loans each with £50,000 drawn) x 0.0975
    it "returns the cumulative drawn amount x 9.75%" do
      expect(claim_limit.total_amount).to eq(Money.new(29_250_00))
    end
  end

  describe "#amount_remaining" do
    context "when a positive number" do
      # £29,250.00 (claim limit) + £1000 (total pre-claim realisations) - £9,375 (total settled amount)
      it "returns the claim limit amount + pre-claim limit realisations - total settled amount" do
        expect(claim_limit.amount_remaining).to eq(Money.new(20_875_00))
      end
    end

    context "when a negative amount" do
      before do
        settled_loan.update_attribute(:settled_amount, Money.new(35_000_00))
      end

      it "returns 0" do
        expect(claim_limit.amount_remaining).to eq(Money.new(0))
      end
    end
  end

  describe "#percentage_remaining" do
    context "when claim_limit and claim_limit_remaining are greater than 0" do
      it "returns the percentage of remaining claim limit" do
        expect(claim_limit.percentage_remaining).to eq(71)
      end
    end

    context "when claim limit is 0" do
      before do
        allow(claim_limit).to receive(:total_amount).and_return(0)
      end

      it "returns 0" do
        expect(claim_limit.percentage_remaining).to eq(0)
      end
    end

    context "when claim_limit_remaining is 0" do
      before do
        allow(claim_limit).to receive(:amount_remaining).and_return(0)
      end

      it "returns 100" do
        expect(claim_limit.percentage_remaining).to eq(100)
      end
    end
  end

end
