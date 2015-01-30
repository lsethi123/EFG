require 'spec_helper'

describe 'Managing CfeAdmins as CfeAdmin' do
  let(:current_user) { FactoryGirl.create(:super_user) }
  before { login_as(current_user, scope: :user) }

  describe 'list' do
    let!(:cfe_admin) { FactoryGirl.create(:cfe_admin, first_name: 'Barry', last_name: 'White') }
    let!(:lender_user) { FactoryGirl.create(:lender_user, first_name: 'David', last_name: 'Bowie') }

    before do
      visit root_path
      click_link 'Manage CfE Admins'
    end

    it do
      expect(page).to have_content('Barry White')
      expect(page).not_to have_content('David Bowie')
    end

    it_should_behave_like 'an admin viewing active and disabled users' do
      let!(:active_user) { cfe_admin }
      let!(:disabled_user) {
        FactoryGirl.create(:cfe_admin,
                           first_name: 'Dave',
                           last_name: 'Smith',
                           disabled: true)
      }
    end
  end

  describe 'create' do
    before do
      ActionMailer::Base.deliveries.clear
    end

    it do
      visit root_path
      click_link 'Manage CfE Admins'

      click_link 'New CfE Admin'

      fill_in 'first_name', 'Bob'
      fill_in 'last_name', 'Flemming'
      fill_in 'email', 'bob.flemming@example.com'

      expect {
        click_button 'Create CfE Admin'
      }.to change(CfeAdmin, :count).by(1)

      expect(page).to have_content('Bob Flemming')
      expect(page).to have_content('bob.flemming@example.com')

      user = CfeAdmin.last!
      expect(user.created_by).to eq(current_user)
      expect(user.modified_by).to eq(current_user)

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::UserCreated)
      expect(admin_audit.auditable).to eq(user)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)

      emails = ActionMailer::Base.deliveries
      expect(emails.size).to eq(1)
      expect(emails.first.to).to eq([ user.email ])
    end
  end

  describe 'update' do
    let!(:user) { FactoryGirl.create(:cfe_admin, first_name: 'Bob', last_name: 'Flemming') }

    it do
      visit root_path
      click_link 'Manage CfE Admins'

      click_link 'Bob Flemming'

      fill_in 'first_name', 'Bill'
      fill_in 'last_name', 'Example'
      fill_in 'email', 'bill.example@example.com'

      click_button 'Update CfE Admin'

      user.reload
      expect(user.email).to eq('bill.example@example.com')
      expect(user.first_name).to eq('Bill')
      expect(user.last_name).to eq('Example')
      expect(user.modified_by).to eq(current_user)

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::UserEdited)
      expect(admin_audit.auditable).to eq(user)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  describe 'unlocking the user' do
    let!(:user) { FactoryGirl.create(:cfe_admin, first_name: 'Bob', last_name: 'Flemming', locked: true) }

    it do
      visit root_path
      click_link 'Manage CfE Admins'
      click_link 'Bob Flemming'
      click_button 'Unlock User'

      expect(user.reload).not_to be_locked

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::UserUnlocked)
      expect(admin_audit.auditable).to eq(user)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  describe 'disabling the user' do
    let!(:user) { FactoryGirl.create(:cfe_admin, first_name: 'Bob', last_name: 'Flemming') }

    it do
      visit root_path
      click_link 'Manage CfE Admins'
      click_link 'Bob Flemming'
      click_button 'Disable User'

      expect(user.reload).to be_disabled

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::UserDisabled)
      expect(admin_audit.auditable).to eq(user)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  describe 'enabling the user' do
    let!(:user) { FactoryGirl.create(:cfe_admin, first_name: 'Bob', last_name: 'Flemming', disabled: true) }

    it do
      visit root_path
      click_link 'Manage CfE Admins'
      click_link 'Disabled'
      click_link 'Bob Flemming'
      click_button 'Enable User'

      expect(user.reload).not_to be_disabled

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::UserEnabled)
      expect(admin_audit.auditable).to eq(user)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  describe 'sending reset password email' do
    let!(:user) {
      user = FactoryGirl.create(
        :cfe_admin,
        first_name: 'Bob',
        last_name: 'Flemming'
      )
      user.encrypted_password = nil
      user.save(validate: false)
      user
    }

    before(:each) do
      ActionMailer::Base.deliveries.clear
    end

    it 'can be sent from edit user page' do
      expect(user.reset_password_token).to be_nil
      expect(user.reset_password_sent_at).to be_nil

      visit root_path
      click_link 'Manage CfE Admins'
      click_link 'Bob Flemming'
      click_button 'Send Reset Password Email'

      expect(page).to have_content(I18n.t('manage_users.reset_password_sent', email: user.email))

      user.reload
      expect(user.reset_password_token).not_to be_nil
      expect(user.reset_password_sent_at).not_to be_nil

      emails = ActionMailer::Base.deliveries
      expect(emails.size).to eq(1)
      expect(emails.first.to).to eq([ user.email ])
    end

    it 'can be sent from user list page' do
      visit root_path
      click_link 'Manage CfE Admins'
      click_button 'Send Reset Password Email'

      expect(page).to have_content(I18n.t('manage_users.reset_password_sent', email: user.email))
      expect(page).to have_content(I18n.t('manage_users.password_set_time_remaining', time_left: '7 days'))
      expect(page).not_to have_css('input', text: 'Send Reset Password Email')
    end

    it 'fails when user does not have an email address' do
      user.email = nil
      user.save(validate: false)

      visit root_path
      click_link 'Manage CfE Admins'
      click_link 'Bob Flemming'
      click_button 'Send Reset Password Email'

      expect(page).to have_content("can't be blank")
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  private
    def fill_in(attribute, value)
      page.fill_in "cfe_admin_#{attribute}", with: value
    end

    def select(attribute, value)
      page.select value, from: "cfe_admin_#{attribute}"
    end
end
