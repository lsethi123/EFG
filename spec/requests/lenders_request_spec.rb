require 'spec_helper'

describe 'lenders' do
  let(:current_user) { FactoryGirl.create(:cfe_admin) }
  before { login_as(current_user, scope: :user) }

  def dispatch
    visit root_path
    click_link 'Manage Lenders'
  end

  describe 'creating a new lender' do
    def dispatch
      super
      click_link 'New Lender'
    end

    it 'does not continue with invalid values' do
      dispatch

      click_button 'Create Lender'

      expect(current_path).to eq(lenders_path)
    end

    it do
      dispatch

      fill_in 'name', 'Bankers'
      select 'loan_scheme', 'EFG only'
      fill_in 'organisation_reference_code', 'BK'
      fill_in 'primary_contact_name', 'Bob Flemming'
      fill_in 'primary_contact_phone', '0123456789'
      fill_in 'primary_contact_email', 'bob@example.com'

      click_button 'Create Lender'

      lender = Lender.last!
      expect(lender.created_by).to eq(current_user)
      expect(lender.modified_by).to eq(current_user)
      expect(lender.name).to eq('Bankers')
      expect(lender.organisation_reference_code).to eq('BK')
      expect(lender.loan_scheme).to eq('E')
      expect(lender.primary_contact_name).to eq('Bob Flemming')
      expect(lender.primary_contact_phone).to eq('0123456789')
      expect(lender.primary_contact_email).to eq('bob@example.com')
      expect(lender.can_use_add_cap).to eq(false)

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::LenderCreated)
      expect(admin_audit.auditable).to eq(lender)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  describe 'editing a lender' do
    let!(:lender) { FactoryGirl.create(:lender, name: 'ACME') }

    def dispatch
      super
      click_link 'ACME'
    end

    it 'does not continue with invalid values' do
      dispatch

      fill_in 'name', ''

      click_button 'Update Lender'

      expect(current_path).to eq(lender_path(lender))
    end

    it do
      dispatch

      fill_in 'name', 'Blankers'
      fill_in 'organisation_reference_code', 'BLK'
      fill_in 'primary_contact_name', 'Flob Bemming'
      fill_in 'primary_contact_phone', '987654321'
      fill_in 'primary_contact_email', 'flob@example.com'
      check 'can_use_add_cap'

      click_button 'Update Lender'

      lender.reload
      expect(lender.modified_by).to eq(current_user)
      expect(lender.name).to eq('Blankers')
      expect(lender.organisation_reference_code).to eq('BLK')
      expect(lender.primary_contact_name).to eq('Flob Bemming')
      expect(lender.primary_contact_phone).to eq('987654321')
      expect(lender.primary_contact_email).to eq('flob@example.com')
      expect(lender.can_use_add_cap).to eq(true)

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::LenderEdited)
      expect(admin_audit.auditable).to eq(lender)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  describe 'activating a lender' do
    let(:lender) { FactoryGirl.create(:lender, disabled: true) }

    def dispatch
      visit edit_lender_path(lender)
    end

    it do
      dispatch
      click_button 'Activate Lender'
      lender.reload
      expect(lender.disabled).to eq(false)
      expect(lender.modified_by).to eq(current_user)

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::LenderEnabled)
      expect(admin_audit.auditable).to eq(lender)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  describe 'deactivating a lender' do
    let(:lender) { FactoryGirl.create(:lender) }

    def dispatch
      visit edit_lender_path(lender)
    end

    it do
      dispatch
      click_button 'Deactivate Lender'
      lender.reload
      expect(lender.disabled).to eq(true)
      expect(lender.modified_by).to eq(current_user)

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::LenderDisabled)
      expect(admin_audit.auditable).to eq(lender)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  private
    def check(attribute)
      page.check "lender_#{attribute}"
    end

    def fill_in(attribute, value)
      page.fill_in "lender_#{attribute}", with: value
    end

    def select(attribute, value)
      page.select value, from: "lender_#{attribute}"
    end
end
