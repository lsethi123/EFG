require 'spec_helper'

describe ClaimLimitCalculator do

  let(:lender) { FactoryGirl.create(:lender) }

  let(:lending_limit) { FactoryGirl.create(:lending_limit, :phase_1, lender: lender) }

  let!(:guaranteed_loan) { FactoryGirl.create(:loan, :guaranteed, lender: lender, lending_limit: lending_limit) }

  describe ".all_with_amount" do
    let(:calculators) { ClaimLimitCalculator.all_with_amount([ lender ]) }

    it "returns array of claim limit calculators, excluding any with 0 amount" do
      calculators.size.should == 1
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
      calculator.cumulative_drawn_amount.should eq(Money.new(1_111_110_00) + guaranteed_loan.initial_draw_change.amount_drawn)
    end
  end

  describe "#pre_claim_realisations_amount" do
    let(:calculator) { ClaimLimitCalculator.new(lender) }
    before { calculator.stub(:phase).and_return(lending_limit.phase) }

    let!(:loan1) { FactoryGirl.create(:loan, :realised, lender: lender, lending_limit: lending_limit) }
    let!(:loan2) { FactoryGirl.create(:loan, :realised, lender: lender, lending_limit: lending_limit) }
    before { LoanRealisation.delete_all }

    let!(:realisation_1) { FactoryGirl.create(:loan_realisation, realised_loan: loan1, realised_amount: Money.new(10_00)) }
    let!(:realisation_2) { FactoryGirl.create(:loan_realisation, realised_loan: loan1, realised_amount: Money.new(20_00)) }
    let!(:realisation_3) { FactoryGirl.create(:loan_realisation, realised_loan: loan2, realised_amount: Money.new(50_00)) }

    it "sums the pre-claim realisations" do
      calculator.pre_claim_realisations_amount.should == Money.new(80_00)
    end

    context "with realisation adjustments" do
      let!(:realisation_adjustment) { FactoryGirl.create(:realisation_adjustment, loan: loan1, amount: Money.new(25_00)) }

      it "subtracts any realisation adjustments" do
        calculator.pre_claim_realisations_amount.should == Money.new(55_00)
      end
    end

    context "with post-claim limit realisations" do
      let!(:post_claim_realisation) { FactoryGirl.create(:loan_realisation, :post, realised_loan: loan1, realised_amount: Money.new(5_00)) }

      it "ignores post-claim limit realisations" do
        calculator.pre_claim_realisations_amount.should == Money.new(80_00)
      end
    end
  end
end
