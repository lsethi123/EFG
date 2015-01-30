require 'spec_helper'

describe LenderUser do
  let(:user) { FactoryGirl.build(:lender_user) }

  it_behaves_like 'User'

  describe 'validations' do
    it 'requires a lender' do
      user.lender = nil
      expect(user).not_to be_valid
    end
  end

  describe '#lenders' do
    before do
      FactoryGirl.create(:lender)
    end

    it "only contains this user's lender" do
      expect(user.lenders.count).to eq(1)
      expect(user.lenders).to include(user.lender)
    end
  end
end
