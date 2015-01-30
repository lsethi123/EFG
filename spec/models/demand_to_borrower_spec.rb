require 'spec_helper'

describe DemandToBorrower do
  describe 'validations' do
    let(:demand_to_borrower) { FactoryGirl.build(:demand_to_borrower) }

    it 'has a valid factory' do
      expect(demand_to_borrower).to be_valid
    end

    it 'strictly requires a loan' do
      expect {
        demand_to_borrower.loan = nil
        demand_to_borrower.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'strictly requires a created_by' do
      expect {
        demand_to_borrower.created_by = nil
        demand_to_borrower.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'strictly requires a modified_date' do
      expect {
        demand_to_borrower.modified_date = ''
        demand_to_borrower.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'requires a date_of_demand' do
      demand_to_borrower.date_of_demand = ''
      expect(demand_to_borrower).not_to be_valid
    end

    it 'requires a demanded_amount' do
      demand_to_borrower.demanded_amount = ''
      expect(demand_to_borrower).not_to be_valid
    end
  end

  describe '#seq' do
    let(:loan) { FactoryGirl.create(:loan, :guaranteed) }

    it 'is incremented per-loan for each DataCorrection' do
      demand_to_borrower1 = FactoryGirl.create(:demand_to_borrower, loan: loan)
      demand_to_borrower2 = FactoryGirl.create(:demand_to_borrower, loan: loan)

      expect(demand_to_borrower1.seq).to eq(1)
      expect(demand_to_borrower2.seq).to eq(2)
    end
  end
end
