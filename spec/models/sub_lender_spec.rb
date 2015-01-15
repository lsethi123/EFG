require 'spec_helper'

describe SubLender do

  describe 'validations' do
    let(:sub_lender) { FactoryGirl.build(:sub_lender) }

    it 'has a valid Factory' do
      sub_lender.should be_valid
    end

    it 'strictly requires a lender' do
      expect {
        sub_lender.lender = nil
        sub_lender.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'requires a name' do
      sub_lender.name = ''
      sub_lender.should_not be_valid
    end
  end

end
