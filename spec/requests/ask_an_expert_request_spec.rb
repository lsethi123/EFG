require 'spec_helper'

describe 'ask an expert' do
  before do
    ActionMailer::Base.deliveries.clear
    login_as(current_user, scope: :user)
    visit root_path
  end

  [
    :lender_admin,
    :lender_user
  ].each do |type|
    context "as a #{type}" do
      let(:current_user) { FactoryGirl.create(type) }
      let!(:expert1) { FactoryGirl.create(:expert_lender_admin, lender: current_user.lender) }
      let!(:expert2) { FactoryGirl.create(:expert_lender_user, lender: current_user.lender) }

      it 'works' do
        click_link 'Ask an Expert'
        expect(page).to have_content(expert1.name)
        expect(page).to have_content(expert2.name)
        fill_in 'ask_an_expert_message', with: 'blah blah'
        click_button 'Submit'

        expect(ActionMailer::Base.deliveries.size).to eq(1)

        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include(expert1.email)
        expect(email.to).to include(expert2.email)
        expect(email.reply_to).to eq([current_user.email])
        expect(email.body).to include('blah blah')
        expect(email.body).to include(current_user.name)

        expect(page).to have_content('Thanks')
      end
    end
  end

  context 'with invalid values' do
    let(:current_user) { FactoryGirl.create(:lender_user) }
    let!(:expert1) { FactoryGirl.create(:expert_lender_admin, lender: current_user.lender) }

    it 'does nothing' do
      click_link 'Ask an Expert'
      click_button 'Submit'
      expect(ActionMailer::Base.deliveries.size).to eq(0)
    end
  end

  context 'when the lender has no experts' do
    let(:current_user) { FactoryGirl.create(:lender_user) }

    it do
      click_link 'Ask an Expert'
      expect(page).to have_content('no experts')
      expect(page).not_to have_selector('#ask_an_expert_message')
    end
  end
end
