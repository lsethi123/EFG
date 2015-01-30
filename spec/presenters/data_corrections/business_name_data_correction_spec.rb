require 'spec_helper'

describe BusinessNameDataCorrection do
  describe 'validations' do
    let(:presenter) { FactoryGirl.build(:business_name_data_correction) }

    it 'has a valid factory' do
      expect(presenter).to be_valid
    end

    it 'requires a business_name' do
      presenter.business_name = ''
      expect(presenter).not_to be_valid
    end
  end

  describe '#save' do
    let(:user) { FactoryGirl.create(:lender_user) }
    let(:loan) { FactoryGirl.create(:loan, :guaranteed, business_name: 'Foo') }
    let(:presenter) { FactoryGirl.build(:business_name_data_correction, created_by: user, loan: loan) }

    context 'success' do
      it 'creates a DataCorrection and updates the loan' do
        presenter.business_name = 'Bar'
        expect(presenter.save).to eq(true)

        data_correction = loan.data_corrections.last!
        expect(data_correction.created_by).to eq(user)
        expect(data_correction.change_type).to eq(ChangeType::BusinessName)
        expect(data_correction.business_name).to eq('Bar')
        expect(data_correction.old_business_name).to eq('Foo')

        loan.reload
        expect(loan.business_name).to eq('Bar')
        expect(loan.modified_by).to eq(user)
      end
    end

    context 'failure' do
      it 'does not update loan' do
        presenter.business_name = nil
        expect(presenter.save).to eq(false)
        loan.reload

        expect(loan.business_name).to eq('Foo')
      end
    end
  end
end
