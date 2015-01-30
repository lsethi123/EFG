require 'spec_helper'

describe 'AuditorUser management' do
  let(:current_user) { FactoryGirl.create(:cfe_admin) }
  before { login_as(current_user, scope: :user) }

  describe 'list' do
    let!(:auditor_user) { FactoryGirl.create(:auditor_user, first_name: 'Barry', last_name: 'White') }
    let!(:lender_user) { FactoryGirl.create(:lender_user, first_name: 'David', last_name: 'Bowie') }

    before do
      visit root_path
      click_link 'Manage Auditor Users'
    end

    it do
      expect(page).to have_content('Barry White')
      expect(page).not_to have_content('David Bowie')
    end

    it_should_behave_like 'an admin viewing active and disabled users' do
      let!(:active_user) { auditor_user }
      let!(:disabled_user) {
        FactoryGirl.create(:auditor_user,
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
      click_link 'Manage Auditor Users'

      click_link 'New Auditor User'

      fill_in 'first_name', 'Bob'
      fill_in 'last_name', 'Flemming'
      fill_in 'email', 'bob.flemming@example.com'

      expect {
        click_button 'Create Auditor User'
      }.to change(AuditorUser, :count).by(1)

      expect(page).to have_content('Bob Flemming')
      expect(page).to have_content('bob.flemming@example.com')

      user = AuditorUser.last!
      expect(user.created_by).to eq(current_user)
      expect(user.modified_by).to eq(current_user)

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::UserCreated)
      expect(admin_audit.auditable).to eq(user)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)

      # verify email is sent to user
      emails = ActionMailer::Base.deliveries
      expect(emails.size).to eq(1)
      expect(emails.first.to).to eq([ user.email ])
    end
  end

  describe 'update' do
    let!(:user) { FactoryGirl.create(:auditor_user, first_name: 'Bob', last_name: 'Flemming') }

    it do
      visit root_path
      click_link 'Manage Auditor Users'

      click_link 'Bob Flemming'

      fill_in 'first_name', 'Bill'
      fill_in 'last_name', 'Example'
      fill_in 'email', 'bill.example@example.com'

      click_button 'Update Auditor User'

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
    let!(:user) { FactoryGirl.create(:auditor_user, first_name: 'Bob', last_name: 'Flemming', locked: true) }

    it do
      visit root_path
      click_link 'Manage Auditor Users'
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
    let!(:user) { FactoryGirl.create(:auditor_user, first_name: 'Bob', last_name: 'Flemming') }

    it do
      visit root_path
      click_link 'Manage Auditor Users'
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
    let!(:user) { FactoryGirl.create(:auditor_user, first_name: 'Bob', last_name: 'Flemming', disabled: true) }

    it do
      visit root_path
      click_link 'Manage Auditor Users'
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

  describe "sending reset password email to user without a password" do
    let!(:user) {
      user = FactoryGirl.create(
        :auditor_user,
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

    it "can be sent from edit user page" do
      expect(user.reset_password_token).to be_nil
      expect(user.reset_password_sent_at).to be_nil

      visit root_path
      click_link 'Manage Auditor Users'
      click_link 'Bob Flemming'
      click_button 'Send Reset Password Email'

      expect(page).to have_content(I18n.t('manage_users.reset_password_sent', email: user.email))

      user.reload
      expect(user.reset_password_token).not_to be_nil
      expect(user.reset_password_sent_at).not_to be_nil

      # verify email is sent to user
      emails = ActionMailer::Base.deliveries
      expect(emails.size).to eq(1)
      expect(emails.first.to).to eq([ user.email ])
    end

    it "can be sent from user list page" do
      visit root_path
      click_link 'Manage Auditor Users'
      click_button 'Send Reset Password Email'

      expect(page).to have_content(I18n.t('manage_users.reset_password_sent', email: user.email))
      expect(page).to have_content(I18n.t('manage_users.password_set_time_remaining', time_left: '7 days'))
      expect(page).not_to have_css('input', text: 'Send Reset Password Email')
    end

    # many imported users will not have an email address
    it 'fails when user does not have an email address' do
      user.email = nil
      user.save(validate: false)

      visit root_path
      click_link 'Manage Auditor Users'
      click_link 'Bob Flemming'
      click_button 'Send Reset Password Email'

      expect(page).to have_content("can't be blank")
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  private
    def fill_in(attribute, value)
      page.fill_in "auditor_user_#{attribute}", with: value
    end

    def select(attribute, value)
      page.select value, from: "auditor_user_#{attribute}"
    end
end
