# encoding: utf-8

require 'spec_helper'

describe DataCorrection do
  it_behaves_like 'LoanModification'

  describe 'validations' do
    let(:loan_modification) { FactoryGirl.build(:data_correction) }

    it 'strictly requires a change_type_id' do
      expect {
        loan_modification.change_type_id = nil
        loan_modification.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end
  end

  describe '#seq' do
    let(:loan) { FactoryGirl.create(:loan, :guaranteed) }

    it 'is incremented for each DataCorrection' do
      correction1 = FactoryGirl.create(:data_correction, loan: loan)
      correction2 = FactoryGirl.create(:data_correction, loan: loan)

      correction1.seq.should == 0
      correction2.seq.should == 1
    end
  end
end
