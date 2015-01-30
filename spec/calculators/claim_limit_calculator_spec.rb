require 'spec_helper'

describe ClaimLimitCalculator do

  let(:lender) { FactoryGirl.create(:lender) }

  let(:lending_limit) { FactoryGirl.create(:lending_limit, :phase_1, lender: lender) }

  let!(:guaranteed_loan) { FactoryGirl.create(:loan, :guaranteed, lender: lender, lending_limit: lending_limit) }

  describe ".all_with_amount" do
    let(:calculators) { ClaimLimitCalculator.all_with_amount([ lender ]) }

    it "returns array of claim limit calculators, excluding any with 0 amount" do
      expect(calculators.size).to eq(1)
    end
  end

  class ClaimLimitCalculatorSubclass < ClaimLimitCalculator
    def phase
      Phase.find(1)
    end
  end

  describe "#cumulative_drawn_amount" do
    subject(:calculator) { ClaimLimitCalculatorSubclass.new(lender) }

    let!(:capital_repayment_holiday) { FactoryGirl.create(:loan_change, :capital_repayment_holiday, amount_drawn: Money.new(10_00), loan: guaranteed_loan) }
    let!(:decrease_term) { FactoryGirl.create(:loan_change, :decrease_term, amount_drawn: Money.new(100_00), loan: guaranteed_loan) }
    let!(:extend_term) { FactoryGirl.create(:loan_change, :extend_term, amount_drawn: Money.new(1_000_00), loan: guaranteed_loan) }
    let!(:lump_sum_repayment) { FactoryGirl.create(:loan_change, :lump_sum_repayment, amount_drawn: Money.new(10_000_00), loan: guaranteed_loan) }
    let!(:reprofile_draws) { FactoryGirl.create(:loan_change, :reprofile_draws, amount_drawn: Money.new(100_000_00), loan: guaranteed_loan) }
    let!(:repayment_frequency) { FactoryGirl.create(:loan_change, :repayment_frequency, amount_drawn: Money.new(1_000_000_00), loan: guaranteed_loan) }
    let!(:not_included) { FactoryGirl.create(:loan_change, :lender_demand_satisfied, amount_drawn: Money.new(100_00), loan: guaranteed_loan) }

    it "includes the drawn amounts for all relevant loan changes" do
      expect(calculator.cumulative_drawn_amount).to eq(Money.new(1_111_110_00) + guaranteed_loan.initial_draw_change.amount_drawn)
    end
  end

end
