require 'spec_helper'

describe AskCfe do
  describe 'validations' do
    let(:user) { FactoryGirl.build(:auditor_user) }
    let(:ask_cfe) { AskCfe.new(message: 'qwerty', user: user) }

    it 'requires a message' do
      ask_cfe.message = ''
      expect(ask_cfe).not_to be_valid
    end

    it 'strictly requires a user' do
      expect {
        ask_cfe.user = nil
        ask_cfe.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it "should have the correct TO address" do
      expect(ask_cfe.to).to eq(EFG::Application.config.cfe_support_email)
    end
  end

end
