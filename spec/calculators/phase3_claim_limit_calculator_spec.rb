require 'spec_helper'

describe 'Claim Limit Phase 3' do

  let(:lender) { FactoryGirl.create(:lender) }

  let(:claim_limit) { Phase3ClaimLimitCalculator.new(lender) }

  before do
    claim_limit.stub(:cumulative_drawn_amount).and_return(Money.new(3_000_000_00))
    claim_limit.stub(:settled_amount).and_return(Money.new(100_000_00))
    claim_limit.stub(:pre_claim_realisations_amount).and_return(Money.new(10_000_00))
  end

  describe "#total_amount" do
    it "returns the cumulative drawn amount at x 9.75% for first million and x 9.225% for the remainder" do
      expect(claim_limit.total_amount).to eq(Money.new(334_500_00))
    end
  end

  describe "#amount_remaining" do
    # £334,500.00 (claim limit) + £10,000 (total pre-claim realisations) - £100,000 (total settled amount)
    it "returns the claim limit amount + pre-claim limit realisations - total settled amount" do
      expect(claim_limit.amount_remaining).to eq(Money.new(244_500_00))
    end
  end

  describe "#percentage_remaining" do
    it "returns the percentage of remaining claim limit" do
      expect(claim_limit.percentage_remaining).to eq(73)
    end
  end

end
