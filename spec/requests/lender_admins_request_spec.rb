require 'spec_helper'

describe 'LenderAdmin management' do
  let!(:lender) { FactoryGirl.create(:lender, name: 'Bankers') }
  let(:current_user) { FactoryGirl.create(:cfe_admin) }

  before { login_as(current_user, scope: :user) }

  describe 'list' do
    let!(:lender_admin) { FactoryGirl.create(:lender_admin, lender: lender, first_name: 'Barry', last_name: 'White') }
    let!(:lender_user) { FactoryGirl.create(:lender_user,  lender: lender, first_name: 'David', last_name: 'Bowie') }

    context 'as a CfE Admin' do
      let(:current_user) { FactoryGirl.create(:cfe_admin) }

      before do
        navigate_cfe_admin_to_lender_admins_for_lender lender
      end

      it 'includes Lender Admins with links to edit' do
        expect(page).to have_content('Bankers')
        expect(page).to have_link(lender_admin.name, href: edit_lender_lender_admin_path(lender, lender_admin))
      end

      it 'does not include Lender Users' do
        expect(page).not_to have_content(lender_user.name)
      end

      it_should_behave_like 'an admin viewing active and disabled users' do
        let!(:active_user) { lender_admin }
        let!(:disabled_user) {
          FactoryGirl.create(:lender_admin,
                             first_name: 'Dave',
                             last_name: 'Smith',
                             disabled: true,
                             lender: lender)
        }
      end
    end

    context 'as a Lender Admin' do
      let(:current_user) { FactoryGirl.create(:lender_admin, lender: lender) }
      let!(:other_lender_admin) { FactoryGirl.create(:lender_admin, first_name: 'Bob', last_name: 'Flemming') }

      before do
        visit root_path
        click_link 'View Lender Admins'
      end

      it 'includes Lender Admins from my Lender' do
        expect(page).to have_content('Bankers')
        expect(page).to have_content(lender_admin.name)
      end

      it 'includes a link to show visible Lender Admin' do
        expect(page).to have_link(lender_admin.name, href: lender_lender_admin_path(lender, lender_admin))
      end

      it 'does not include a link to edit visible Lender Admin' do
        expect(page).not_to have_link(lender_admin.name, href: edit_lender_lender_admin_path(lender, lender_admin))
      end

      it 'does not include Lender Users' do
        expect(page).not_to have_content(lender_user.name)
      end

      it 'does not include Lender Admins from other Lender' do
        expect(page).not_to have_content(other_lender_admin.name)
      end

      it_should_behave_like 'an admin viewing active and disabled users' do
        let!(:active_user) { lender_admin }
        let!(:disabled_user) {
          FactoryGirl.create(:lender_admin,
                             first_name: 'Dave',
                             last_name: 'Smith',
                             disabled: true,
                             lender: active_user.lender)
        }
      end
    end
  end

  describe 'create' do
    before do
      ActionMailer::Base.deliveries.clear
    end

    it do
      navigate_cfe_admin_to_lender_admins_for_lender lender

      click_link 'New Lender Admin'

      fill_in 'first_name', 'Bob'
      fill_in 'last_name', 'Flemming'
      fill_in 'email', 'bob.flemming@example.com'

      expect {
        click_button 'Create Lender Admin'
      }.to change(LenderAdmin, :count).by(1)

      expect(page).to have_content('Bankers')
      expect(page).to have_content('Bob Flemming')
      expect(page).to have_content('bob.flemming@example.com')

      user = LenderAdmin.last!
      expect(user.lender).to eq(lender)
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
    let!(:user) { FactoryGirl.create(:lender_admin, first_name: 'Bob', last_name: 'Flemming', lender: lender) }

    it do
      navigate_cfe_admin_to_lender_admins_for_lender lender

      click_link 'Bob Flemming'

      expect(page).not_to have_selector('#lender_admin_lender_id')

      fill_in 'first_name', 'Bill'
      fill_in 'last_name', 'Example'
      fill_in 'email', 'bill.example@example.com'

      click_button 'Update Lender Admin'

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
    let!(:lender_admin) {
      FactoryGirl.create(:lender_admin,
                         first_name: 'Bob',
                         last_name: 'Flemming',
                         lender: lender,
                         locked: true)
    }

    context 'as a Lender Admin' do
      let(:current_user) { FactoryGirl.create(:lender_admin, lender: lender) }

      it 'unlocks the user' do
        visit root_path
        click_link 'View Lender Admins'
        click_link 'Bob Flemming'
        click_button 'Unlock User'

        expect(lender_admin.reload).not_to be_locked
      end
    end

    context 'as a Cfe Admin' do
      it 'unlocks the user' do
        navigate_cfe_admin_to_lender_admins_for_lender lender
        click_link 'Bob Flemming'
        click_button 'Unlock User'

        expect(lender_admin.reload).not_to be_locked
      end
    end

    after do
      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::UserUnlocked)
      expect(admin_audit.auditable).to eq(lender_admin)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  describe 'disabling the user' do
    let!(:lender_admin) {
      FactoryGirl.create(:lender_admin,
                         first_name: 'Bob',
                         last_name: 'Flemming',
                         lender: lender)
    }

    context 'as a Lender Admin' do
      let(:current_user) { FactoryGirl.create(:lender_admin, lender: lender) }

      it 'disables the user' do
        visit root_path
        click_link 'View Lender Admins'
        click_link 'Bob Flemming'
        click_button 'Disable User'

        expect(lender_admin.reload).to be_disabled
      end
    end

    context 'as a Cfe Admin' do
      it 'disables the user' do
        navigate_cfe_admin_to_lender_admins_for_lender lender
        click_link 'Bob Flemming'
        click_button 'Disable User'

        expect(lender_admin.reload).to be_disabled
      end
    end

    after do
      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::UserDisabled)
      expect(admin_audit.auditable).to eq(lender_admin)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  describe 'enabling the user' do
    let!(:lender_admin) {
      FactoryGirl.create(:lender_admin,
                         first_name: 'Bob',
                         last_name: 'Flemming',
                         lender: lender,
                         disabled: true)
    }

    context 'as a Lender Admin' do
      let(:current_user) { FactoryGirl.create(:lender_admin, lender: lender) }

      it 'enables the user' do
        visit root_path
        click_link 'View Lender Admins'
        click_link 'Disabled'
        click_link 'Bob Flemming'
        click_button 'Enable User'

        expect(lender_admin.reload).not_to be_disabled
      end
    end

    context 'as a CfE Admin' do
      it 'enables the user' do
        navigate_cfe_admin_to_lender_admins_for_lender lender
        click_link 'Disabled'
        click_link 'Bob Flemming'
        click_button 'Enable User'

        expect(lender_admin.reload).not_to be_disabled
      end
    end

    after do
      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::UserEnabled)
      expect(admin_audit.auditable).to eq(lender_admin)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  describe "sending reset password email to user without a password" do
    let!(:user) {
      user = FactoryGirl.create(
        :lender_admin,
        first_name: 'Bob',
        last_name: 'Flemming',
        lender: lender,
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

      navigate_cfe_admin_to_lender_admins_for_lender lender
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
      navigate_cfe_admin_to_lender_admins_for_lender lender
      click_button 'Send Reset Password Email'

      expect(page).to have_content(I18n.t('manage_users.reset_password_sent', email: user.email))
      expect(page).to have_content(I18n.t('manage_users.password_set_time_remaining', time_left: '7 days'))
      expect(page).not_to have_css('input', text: 'Send Reset Password Email')
    end

    # many imported users will not have an email address
    it 'fails when user does not have an email address' do
      user.email = nil
      user.save(validate: false)

      navigate_cfe_admin_to_lender_admins_for_lender lender
      click_link 'Bob Flemming'
      click_button 'Send Reset Password Email'

      expect(page).to have_content("can't be blank")
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  private
    def fill_in(attribute, value)
      page.fill_in "lender_admin_#{attribute}", with: value
    end

    def select(attribute, value)
      page.select value, from: "lender_admin_#{attribute}"
    end
end
