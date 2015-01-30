require 'spec_helper'

describe 'password policy' do

  describe 'expiry' do

    %w(
      auditor_user
      cfe_admin
      cfe_user
      lender_admin
      lender_user
      premium_collector_user
    ).each do |user_type|

      it "should be unable to login as a #{user_type.humanize} when the password has expired" do
        current_user = FactoryGirl.create(user_type)
        current_user.password_changed_at = current_user.password_changed_at - current_user.class.expire_password_after
        current_user.save!

        visit root_path
        submit_sign_in_form(current_user.username, current_user.password)
        expect(page).to have_content(I18n.t('devise.password_expired.change_required'))
      end

      it "should be able to login as a #{user_type.humanize} when the password has not expired" do
        current_user = FactoryGirl.create(user_type)
        current_user.password_changed_at = Time.now.utc
        current_user.save!

        visit root_path
        submit_sign_in_form(current_user.username, current_user.password)
        expect(page).to have_content('Logout')
      end

      it "should be possible to reset an expired password as a #{user_type.humanize}" do
        current_user = FactoryGirl.create(user_type)
        current_user.password_changed_at = current_user.password_changed_at - current_user.class.expire_password_after
        current_user.save!

        visit root_path
        submit_sign_in_form(current_user.username, current_user.password)
        expect(page).to have_content(I18n.t('devise.password_expired.change_required'))

        # We have a password history policy now :)
        fill_in 'user_current_password', with: current_user.password
        fill_in 'user_password', with: current_user.password + 'foo'
        fill_in 'user_password_confirmation', with: current_user.password + 'foo'
        click_button 'Change Password'

        expect(page).to have_content(I18n.t('devise.password_expired.updated'))
      end
    end
  end
end
