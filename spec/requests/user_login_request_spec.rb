require 'spec_helper'

describe 'user login' do
  describe 'Account locking' do
    let(:user) { FactoryGirl.create(:lender_user) }

    it 'should lock a user account after a number of failed login attempts' do
      visit root_path

      (Devise.maximum_attempts + 1).times do
        submit_sign_in_form user.username, 'wrong!'
      end

      # incorrect authentication details for locked account shows generic flash message
      submit_sign_in_form user.username, 'wrong!'
      page.should have_content(I18n.t('devise.failure.locked'))

      # correct authentication details allows login
      # but all pages redirect to page informing user their account is locked
      submit_sign_in_form user.username, 'password'
      page.should have_content('Your account has been locked')
      page.current_path.should == account_locked_path

      # check other pages aren't accessible
      visit loan_states_path
      page.should have_content('Your account has been locked')
      page.current_path.should == account_locked_path
    end
  end

  describe 'as a user belonging to a disabled lender' do
    shared_examples 'disabled lender login' do
      it 'should be able to login' do
        visit root_path
        submit_sign_in_form user.username, 'password'
        page.should have_content(I18n.t('devise.failure.invalid'))
      end
    end

    let(:lender) { FactoryGirl.create(:lender, disabled: true) }

    context 'LenderAdmin' do
      it_should_behave_like 'disabled lender login' do
        let(:user) { FactoryGirl.create(:lender_admin, lender: lender) }
      end
    end

    context 'LenderUser' do
      it_should_behave_like 'disabled lender login' do
        let(:user) { FactoryGirl.create(:lender_user, lender: lender) }
      end
    end
  end

  def submit_sign_in_form(username, password)
    fill_in 'user_username', with: username
    fill_in 'user_password', with: password
    click_button 'Sign In'
  end
end