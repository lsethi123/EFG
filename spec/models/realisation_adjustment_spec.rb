require 'spec_helper'

describe RealisationAdjustment do
  describe 'validations' do
    let(:realisation_adjustment) { FactoryGirl.build(:realisation_adjustment) }

    it 'has a valid factory' do
      expect(realisation_adjustment).to be_valid
    end

    it 'strictly requires a loan' do
      expect {
        realisation_adjustment.loan = nil
        realisation_adjustment.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'strictly requires a creator' do
      expect {
        realisation_adjustment.created_by = nil
        realisation_adjustment.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'requires an amount' do
      realisation_adjustment.amount = nil
      realisation_adjustment.should_not be_valid
    end

    it 'requires an amount greater than 0' do
      realisation_adjustment.amount = Money.new(0)
      realisation_adjustment.should_not be_valid

      realisation_adjustment.amount = Money.new(-10)
      realisation_adjustment.should_not be_valid
    end

    it 'requires date' do
      realisation_adjustment.date = ''
      realisation_adjustment.should_not be_valid
    end
  end
end
