require 'spec_helper'

describe LoanDemandAgainstGovernment do

  let(:loan_demand_against_government) { FactoryGirl.build(:loan_demand_against_government) }

  let(:loan) { loan_demand_against_government.loan }

  describe 'validations' do

    it 'should have a valid factory' do
      expect(loan_demand_against_government).to be_valid
    end

    it 'should be invalid without dti demanded oustanding' do
      loan_demand_against_government.dti_demand_outstanding = nil
      expect(loan_demand_against_government).not_to be_valid
    end

    it 'should be invalid without a demanded date' do
      loan_demand_against_government.dti_demanded_on = ''
      expect(loan_demand_against_government).not_to be_valid
    end

    it 'should be invalid without a DED code' do
      loan_demand_against_government.dti_ded_code = ''
      expect(loan_demand_against_government).not_to be_valid
    end

    it "should be invalid when demanded amount is greater than total amount drawn" do
      loan_demand_against_government.dti_demand_outstanding = loan.cumulative_drawn_amount + Money.new(1_00)
      expect(loan_demand_against_government).not_to be_valid

      loan_demand_against_government.dti_demand_outstanding = loan.cumulative_drawn_amount
      expect(loan_demand_against_government).to be_valid
    end

    it "should be invalid when demanded date is before demand to borrower date" do
      loan_demand_against_government.dti_demanded_on = loan.borrower_demanded_on - 1.day
      expect(loan_demand_against_government).not_to be_valid

      loan_demand_against_government.dti_demanded_on = loan.borrower_demanded_on
      expect(loan_demand_against_government).to be_valid
    end

    %w(sflg legacy_sflg).each do |loan_type|
      context "when #{loan_type} loan" do
        let(:loan_demand_against_government) { FactoryGirl.build("#{loan_type}_loan_demand_against_government") }

        it "should be invalid without dti_interest" do
          loan_demand_against_government.dti_interest = nil
          expect(loan_demand_against_government).not_to be_valid
        end

        it "should be invalid without dti_break_costs" do
          loan_demand_against_government.dti_break_costs = nil
          expect(loan_demand_against_government).not_to be_valid
        end
      end
    end
  end

  describe "#dti_amount_claimed" do
    it "should be set when record is saved" do
      expect(loan_demand_against_government.dti_amount_claimed).to be_blank
      loan_demand_against_government.save
      expect(loan_demand_against_government.dti_amount_claimed).to eq(Money.new(7500_00)) # 75% of £10,000 (#dti_amount_outstanding)
    end

    it "should include interest and break costs in #dti_amount_claimed when non-EFG loan" do
      loan.loan_scheme = Loan::SFLG_SCHEME
      loan_demand_against_government.dti_interest = Money.new(1_000_00)
      loan_demand_against_government.dti_break_costs = Money.new(500_00)

      loan_demand_against_government.save
      expect(loan_demand_against_government.dti_amount_claimed).to eq(Money.new(8625_00)) # 75% of £11,500 (#dti_amount_outstanding + #dti_interest + #dti_break_costs)
    end
  end
end
