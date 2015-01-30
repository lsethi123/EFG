require 'spec_helper'

describe SortcodeDataCorrection do
  describe 'validations' do
    let(:presenter) { FactoryGirl.build(:sortcode_data_correction) }

    it 'has a valid factory' do
      expect(presenter).to be_valid
    end

    it 'requires a sortcode' do
      presenter.sortcode = ''
      expect(presenter).not_to be_valid
    end
  end

  describe '#save' do
    let(:user) { FactoryGirl.create(:lender_user) }
    let(:loan) { FactoryGirl.create(:loan, :guaranteed, sortcode: '123456', last_modified_at: 1.year.ago) }
    let(:presenter) { FactoryGirl.build(:sortcode_data_correction, created_by: user, loan: loan) }

    context 'success' do
      it 'creates a DataCorrection and updates the loan' do
        presenter.sortcode = '654321'
        expect(presenter.save).to eq(true)

        data_correction = loan.data_corrections.last!
        expect(data_correction.change_type).to eq(ChangeType::DataCorrection)
        expect(data_correction.created_by).to eq(user)
        expect(data_correction.sortcode).to eq('654321')
        expect(data_correction.old_sortcode).to eq('123456')

        loan.reload
        expect(loan.last_modified_at).not_to eq(1.year.ago)
        expect(loan.modified_by).to eq(user)
        expect(loan.sortcode).to eq('654321')
      end
    end

    context 'failure' do
      it 'does not update the loan' do
        presenter.sortcode = ''
        expect(presenter.save).to eq(false)

        loan.reload
        expect(loan.sortcode).to eq('123456')
      end
    end
  end
end
