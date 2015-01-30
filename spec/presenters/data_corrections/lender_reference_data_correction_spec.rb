require 'spec_helper'

describe LenderReferenceDataCorrection do
  describe 'validations' do
    let(:presenter) { FactoryGirl.build(:lender_reference_data_correction) }

    it 'has a valid factory' do
      expect(presenter).to be_valid
    end

    it 'requires a lender_reference' do
      presenter.lender_reference = ''
      expect(presenter).not_to be_valid
    end
  end

  describe '#save' do
    let(:user) { FactoryGirl.create(:lender_user) }
    let(:loan) { FactoryGirl.create(:loan, :guaranteed, lender_reference: 'Foo') }
    let(:presenter) { FactoryGirl.build(:lender_reference_data_correction, created_by: user, loan: loan) }

    context 'success' do
      it 'creates a DataCorrection and updates the loan' do
        presenter.lender_reference = 'Bar'
        expect(presenter.save).to eq(true)

        data_correction = loan.data_corrections.last!
        expect(data_correction.created_by).to eq(user)
        expect(data_correction.change_type).to eq(ChangeType::LenderReference)
        expect(data_correction.lender_reference).to eq('Bar')
        expect(data_correction.old_lender_reference).to eq('Foo')

        loan.reload
        expect(loan.lender_reference).to eq('Bar')
        expect(loan.modified_by).to eq(user)
      end
    end

    context 'failure' do
      it 'does not update loan' do
        presenter.lender_reference = nil
        expect(presenter.save).to eq(false)
        loan.reload

        expect(loan.lender_reference).to eq('Foo')
      end
    end
  end
end
