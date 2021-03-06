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
        page.should have_content(expert1.name)
        page.should have_content(expert2.name)
        fill_in 'ask_an_expert_message', with: 'blah blah'
        click_button 'Submit'

        ActionMailer::Base.deliveries.size.should == 1

        email = ActionMailer::Base.deliveries.last
        email.to.should include(expert1.email)
        email.to.should include(expert2.email)
        email.reply_to.should == [current_user.email]
        email.body.should include('blah blah')
        email.body.should include(current_user.name)

        page.should have_content('Thanks')
      end
    end
  end

  context 'with invalid values' do
    let(:current_user) { FactoryGirl.create(:lender_user) }
    let!(:expert1) { FactoryGirl.create(:expert_lender_admin, lender: current_user.lender) }

    it 'does nothing' do
      click_link 'Ask an Expert'
      click_button 'Submit'
      ActionMailer::Base.deliveries.size.should == 0
    end
  end

  context 'when the lender has no experts' do
    let(:current_user) { FactoryGirl.create(:lender_user) }

    it do
      click_link 'Ask an Expert'
      page.should have_content('no experts')
      page.should_not have_selector('#ask_an_expert_message')
    end
  end
end
