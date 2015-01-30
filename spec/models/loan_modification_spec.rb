require 'spec_helper'

describe LoanModification do
  describe '#changes' do
    let(:loan_modification) { FactoryGirl.build(:data_correction) }

    it 'contains only fields that have a value' do
      loan_modification.old_business_name = 'Foo'
      loan_modification.business_name = 'Bar'

      expect(loan_modification.changes.size).to eq(1)
      expect(loan_modification.changes.first[:old_attribute]).to eq('old_business_name')
      expect(loan_modification.changes.first[:old_value]).to eq('Foo')
      expect(loan_modification.changes.first[:attribute]).to eq('business_name')
      expect(loan_modification.changes.first[:value]).to eq('Bar')
    end

    it 'contains fields where the old value was NULL' do
      loan_modification.old_lender_reference = nil
      loan_modification.lender_reference = 'LENDER REF'

      expect(loan_modification.changes.size).to eq(1)
      expect(loan_modification.changes.first[:old_attribute]).to eq('old_lender_reference')
      expect(loan_modification.changes.first[:old_value]).to eq(nil)
      expect(loan_modification.changes.first[:attribute]).to eq('lender_reference')
      expect(loan_modification.changes.first[:value]).to eq('LENDER REF')
    end
  end
end
