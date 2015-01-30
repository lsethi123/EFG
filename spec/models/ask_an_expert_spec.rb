require 'spec_helper'

describe AskAnExpert do
  describe 'validations' do
    let(:user) { FactoryGirl.build(:lender_user) }
    let(:ask_an_expert) { AskAnExpert.new(expert_users: [user], message: 'qwerty', user: user) }

    it 'requires a message' do
      ask_an_expert.message = ''
      expect(ask_an_expert).not_to be_valid
    end

    it 'strictly requires a user' do
      expect {
        ask_an_expert.user = nil
        ask_an_expert.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'requires at least one "to" email' do
      ask_an_expert.expert_users = []
      expect(ask_an_expert).not_to be_valid

      ask_an_expert.expert_users = [double(email: 'a@example.com')]
      expect(ask_an_expert).to be_valid
    end
  end

  describe '#to' do
    let(:user) { FactoryGirl.build(:lender_user) }
    let(:ask_an_expert) { AskAnExpert.new(message: 'qwerty', user: user) }
    let(:expert1) { double(email: 'a@example.com') }
    let(:expert2) { double(email: '') }
    let(:expert3) { double(email: 'b@example.com') }

    it 'removes blank values' do
      ask_an_expert.expert_users = [expert2]
      expect(ask_an_expert.to).to eq([])
    end

    it 'removes duplicates' do
      ask_an_expert.expert_users = [expert1, expert3, expert1]
      expect(ask_an_expert.to).to eq(%w(a@example.com b@example.com))
    end
  end
end
