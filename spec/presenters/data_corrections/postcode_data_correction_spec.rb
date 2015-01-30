require 'spec_helper'

describe PostcodeDataCorrection do
  describe 'validations' do
    let(:presenter) { FactoryGirl.build(:postcode_data_correction) }

    it 'has a valid factory' do
      expect(presenter).to be_valid
    end

    it 'requires a postcode' do
      presenter.postcode = ''
      expect(presenter).not_to be_valid
    end
  end

  describe '#save' do
    let(:user) { FactoryGirl.create(:lender_user) }
    let(:loan) { FactoryGirl.create(:loan, :guaranteed, postcode: 'EC1R 4RP') }
    let(:presenter) { FactoryGirl.build(:postcode_data_correction, created_by: user, loan: loan) }

    context 'success' do
      it 'creates a DataCorrection and updates the loan' do
        presenter.postcode = 'EC1A 9PN'
        expect(presenter.save).to eq(true)

        data_correction = loan.data_corrections.last!
        expect(data_correction.created_by).to eq(user)
        expect(data_correction.change_type).to eq(ChangeType::Postcode)
        expect(data_correction.postcode).to eq('EC1A 9PN')
        expect(data_correction.old_postcode).to eq('EC1R 4RP')

        loan.reload
        expect(loan.postcode).to eq('EC1A 9PN')
        expect(loan.modified_by).to eq(user)
      end
    end

    context 'failure' do
      it 'does not update loan' do
        presenter.postcode = nil
        expect(presenter.save).to eq(false)

        loan.reload
        expect(loan.postcode).to eq('EC1R 4RP')
      end
    end
  end
end
