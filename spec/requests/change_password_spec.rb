require 'spec_helper'

describe 'Change password' do

  %w(
    auditor_user
    cfe_admin
    cfe_user
    lender_admin
    lender_user
    premium_collector_user
  ).each do |user_type|

    it "should allow a #{user_type.humanize} to update their password" do
      current_user = FactoryGirl.create(user_type)
      login_as(current_user, scope: :user)

      visit root_path
      visit edit_change_password_path
      click_link 'Change Password'

      new_password = 'new-password-W1bbL3'
      fill_in "#{user_type}_password", with: new_password
      fill_in "#{user_type}_password_confirmation", with: new_password
      click_button 'Update Password'

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::UserPasswordChanged)
      expect(admin_audit.auditable).to eq(current_user)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)

      expect(page).to have_content('Your password has been successfully changed')
      expect(page.current_url).to eq(root_url)

      # sign in with new password

      click_link "Logout"
      fill_in 'user_username', with: current_user.username
      fill_in 'user_password', with: new_password
      click_button 'Sign In'

      expect(page).to have_content(I18n.t('devise.sessions.signed_in'))
      expect(page.current_url).to eq(root_url)
    end

    it "should not allow weak passwords" do
      current_user = FactoryGirl.create(user_type)
      login_as(current_user, scope: :user)

      visit root_path
      visit edit_change_password_path
      click_link 'Change Password'

      fill_in "#{user_type}_password", with: 'password'
      fill_in "#{user_type}_password_confirmation", with: 'password'
      click_button 'Update Password'

      expect(page).to have_content(I18n.t('errors.messages.insufficient_entropy', entropy: 5, minimum_entropy: Devise::Models::Strengthened::MINIMUM_ENTROPY))
    end

    it "should not allow passwords to be changed to the same password" do
      current_user = FactoryGirl.create(user_type)
      login_as(current_user, scope: :user)

      visit root_path
      visit edit_change_password_path
      click_link 'Change Password'

      fill_in "#{user_type}_password", with: current_user.password
      fill_in "#{user_type}_password_confirmation", with: current_user.password
      click_button 'Update Password'

      expect(page).to have_content((I18n.t('errors.messages.taken_in_past')))
    end

  end

  it 'cannot be accessed unless logged in' do
    visit edit_change_password_path
    expect(page).to have_content(I18n.t('devise.failure.unauthenticated'))
  end

end
