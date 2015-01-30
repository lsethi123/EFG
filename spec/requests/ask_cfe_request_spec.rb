require 'spec_helper'

describe 'ask British Business Bank' do
  before do
    ActionMailer::Base.deliveries.clear
    login_as(current_user, scope: :user)
    visit root_path
    click_link 'Ask British Business Bank'
  end

  [
    :auditor_user,
    :expert_lender_admin,
    :expert_lender_user,
    :premium_collector_user
  ].each do |type|
    context "as a #{type}" do
      let(:current_user) { FactoryGirl.create(type) }

      it 'works' do
        fill_in 'ask_cfe_message', with: 'blah blah'
        click_button 'Submit'

        expect(ActionMailer::Base.deliveries.size).to eq(1)

        email = ActionMailer::Base.deliveries.last
        expect(email.reply_to).to eq([current_user.email])
        expect(email.body).to include('blah blah')
        expect(email.body).to include(current_user.name)

        expect(page).to have_content('Thanks')
      end
    end
  end

  context 'with invalid values' do
    let(:current_user) { FactoryGirl.create(:auditor_user) }

    it 'does nothing' do
      click_button 'Submit'
      expect(ActionMailer::Base.deliveries.size).to eq(0)
    end
  end
end
