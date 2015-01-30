require 'spec_helper'

describe 'expert users' do
  let(:current_user) { FactoryGirl.create(:lender_admin) }
  let(:lender) { current_user.lender }
  before { login_as(current_user, scope: :user) }

  describe 'listing' do
    let!(:expert_user1) { FactoryGirl.create(:expert_lender_user, lender: lender) }
    let!(:expert_user2) { FactoryGirl.create(:expert_lender_user) }

    it do
      visit root_path
      click_link 'Manage Experts'

      expect(page).to have_content(expert_user1.name)
      expect(page).not_to have_content(expert_user2.name)
    end
  end

  describe 'creating' do
    let!(:lender_user1) { FactoryGirl.create(:lender_user, lender: lender) }
    let!(:lender_user2) { FactoryGirl.create(:lender_user, lender: lender, first_name: 'Ted', last_name: 'Super') }

    it do
      visit root_path
      click_link 'Manage Experts'

      select 'Ted Super', from: 'expert[user_id]'
      click_button 'Add Expert'

      expert = Expert.last!
      expect(expert.lender).to eq(lender)
      expect(expert.user).to eq(lender_user2)

      expect(lender_user2).to be_expert

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::LenderExpertAdded)
      expect(admin_audit.auditable).to eq(lender_user2)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  describe 'deleting' do
    let!(:expert_user) { FactoryGirl.create(:expert_lender_user, lender: lender) }

    it do
      visit root_path
      click_link 'Manage Experts'
      click_button 'Remove'

      expect(lender.experts.count).to eq(0)
      expect(expert_user).not_to be_expert

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::LenderExpertRemoved)
      expect(admin_audit.auditable).to eq(expert_user)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end
end
