require 'spec_helper'

describe 'Claim Limit Phase 4' do

  let(:lender) { FactoryGirl.create(:lender) }

  let(:claim_limit) { Phase4ClaimLimitCalculator.new(lender) }

  before do
    allow(claim_limit).to receive(:cumulative_drawn_amount).and_return(Money.new(300_000_00))
    allow(claim_limit).to receive(:settled_amount).and_return(Money.new(10_000_00))
    allow(claim_limit).to receive(:pre_claim_realisations_amount).and_return(Money.new(1_000_00))
  end

  describe "#total_amount" do
    it "returns the cumulative drawn amount x 15%" do
      expect(claim_limit.total_amount).to eq(Money.new(45_000_00))
    end
  end

  describe "#amount_remaining" do
    # £45,000.00 (claim limit) + £1000 (total pre-claim realisations) - £10,000 (total settled amount)
    it "returns the claim limit amount + pre-claim limit realisations - total settled amount" do
      expect(claim_limit.amount_remaining).to eq(Money.new(36_000_00))
    end
  end

  describe "#percentage_remaining" do
    it "returns the percentage of remaining claim limit" do
      expect(claim_limit.percentage_remaining).to eq(80)
    end
  end

end
