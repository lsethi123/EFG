require 'spec_helper'

feature "a user resetting their password" do
  after { ActionMailer::Base.deliveries.clear }

  specify "mails them a reset link, reset's their password and logs them in" do
    user = FactoryGirl.create(:lender_user, username: 'batman', first_name: 'Bruce', last_name: 'Wayne')

    visit new_user_password_path
    expect(page).to have_content('Reset Your Password')

    fill_in 'user[username]', with: 'batman'
    click_button 'Send Reset Instructions'

    expect(ActionMailer::Base.deliveries.size).to eq(1)

    reset_password_email = ActionMailer::Base.deliveries.last
    reset_password_uris = URI.extract(reset_password_email.body.to_s, ['http'])
    reset_password_uri = URI.parse(reset_password_uris.first)

    visit reset_password_uri.request_uri

    expect(page).to have_content('Set Your Password')

    fill_in 'user[password]', with: 'bounds2540{uprightly'
    fill_in 'user[password_confirmation]', with: 'bounds2540{uprightly'
    click_button 'Change Password'

    expect(page).not_to have_content('Reset password token is invalid')
    expect(page).to have_content('Welcome Bruce')
  end
end
