require 'spec_helper'

describe UserManagementHelper do
  describe '#most_recent_login_time' do
    context 'when user current_sign_in_at is present' do
      let(:user) {
        FactoryGirl.build_stubbed(:user,
                                  :current_sign_in_at => Time.gm(2013, 2, 1, 20, 15, 1))
      }

      it 'returns current_sign_in_at correctly formatted' do
        expect(most_recent_login_time(user)).to eq('01/02/2013 20:15:01')
      end
    end

    context 'when user current_sign_in_at is blank' do
      let(:user) {
        FactoryGirl.build_stubbed(:user,
                                  :current_sign_in_at => nil)
      }

      it 'returns nil' do
        expect(most_recent_login_time(user)).to be_nil
      end
    end
  end
end
