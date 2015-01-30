# encoding: utf-8

require 'spec_helper'

describe 'LendingLimits' do
  let(:current_user) { FactoryGirl.create(:cfe_admin) }
  before { login_as(current_user, scope: :user) }
  let(:phase) { Phase.find(1) }
  let!(:lender) { FactoryGirl.create(:lender, name: 'ACME') }

  describe 'create' do
    before do
      visit root_path
      click_link 'Manage Lenders'

      # We have 2 links to the lending limit:
      # - lender.current_annual_lending_limit_allocation
      # - lender.current_specific_lending_limit_allocation
      # See views/lenders/index.html.erb
      first(:link, "£0.00").click

      click_link 'New Lending Limit'
    end

    it 'does not continue with invalid values' do
      click_button 'Create Lending Limit'
      expect(current_path).to eq(lender_lending_limits_path(lender))
    end

    it do
      choose_radio_button :allocation_type_id, LendingLimitType::Annual.id
      fill_in :name, 'This year'
      select :phase_id, 'Phase 1 (FY 2009/10)'
      fill_in :starts_on, '1/1/12'
      fill_in :ends_on, '31/12/12'
      fill_in :allocation, '5000000'
      click_button 'Create Lending Limit'

      lending_limit = LendingLimit.last
      expect(lending_limit.lender).to eq(lender)
      expect(lending_limit.phase).to eq(phase)
      expect(lending_limit.modified_by).to eq(current_user)
      expect(lending_limit.active).to eq(true)
      expect(lending_limit.name).to eq('This year')
      expect(lending_limit.starts_on).to eq(Date.new(2012, 1, 1))
      expect(lending_limit.ends_on).to eq(Date.new(2012, 12, 31))
      expect(lending_limit.allocation).to eq(Money.new(5_000_000_00))

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::LendingLimitCreated)
      expect(admin_audit.auditable).to eq(lending_limit)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  describe 'update' do
    let!(:lending_limit) { FactoryGirl.create(:lending_limit, lender: lender, phase_id: phase.id, name: 'Foo', allocation: Money.new(1_000_00)) }

    before do
      visit root_path
      click_link 'Manage Lenders'
      click_link '£1,000.00'
      click_link 'Foo'
    end

    it do
      expect(page).not_to have_selector('input[id^=lending_limit_allocation_type_id]')
      expect(page).not_to have_selector('#lending_limit_ends_on')
      expect(page).not_to have_selector('#lending_limit_starts_on')

      fill_in :name, 'Updated'
      select :phase_id, 'Phase 1 (FY 2009/10)'
      fill_in :allocation, '9999.99'
      click_button 'Update Lending Limit'

      lending_limit.reload
      expect(lending_limit.lender).to eq(lender)
      expect(lending_limit.phase).to eq(phase)
      expect(lending_limit.modified_by).to eq(current_user)
      expect(lending_limit.active).to eq(true)
      expect(lending_limit.name).to eq('Updated')
      expect(lending_limit.allocation).to eq(Money.new(9_999_99))

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::LendingLimitEdited)
      expect(admin_audit.auditable).to eq(lending_limit)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  describe 'activating a LendingLimit' do
    let!(:lending_limit) { FactoryGirl.create(:lending_limit, :inactive, lender: lender, name: 'Foo', allocation: Money.new(1_000_00)) }

    before do
      visit root_path
      click_link 'Manage Lenders'
      click_link 'Lending Limits'
      click_link lending_limit.name
    end

    it do
      click_button 'Activate Lending Limit'

      lending_limit.reload
      expect(lending_limit.active).to eq(true)
      expect(lending_limit.modified_by).to eq(current_user)

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::LendingLimitActivated)
      expect(admin_audit.auditable).to eq(lending_limit)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  describe 'deactivating a LendingLimit' do
    let!(:lending_limit) { FactoryGirl.create(:lending_limit, :active, lender: lender, name: 'Foo', allocation: Money.new(1_000_00)) }

    before do
      visit root_path
      click_link 'Manage Lenders'
      click_link '£1,000.00'
      click_link lending_limit.name
    end

    it do
      click_button 'Deactivate Lending Limit'

      lending_limit.reload
      expect(lending_limit.active).to eq(false)
      expect(lending_limit.modified_by).to eq(current_user)

      admin_audit = AdminAudit.last!
      expect(admin_audit.action).to eq(AdminAudit::LendingLimitRemoved)
      expect(admin_audit.auditable).to eq(lending_limit)
      expect(admin_audit.modified_by).to eq(current_user)
      expect(admin_audit.modified_on).to eq(Date.current)
    end
  end

  private
    def choose_radio_button(attribute, value)
      choose "lending_limit_#{attribute}_#{value}"
    end

    def fill_in(attribute, value)
      page.fill_in "lending_limit_#{attribute}", with: value
    end

    def select(attribute, value)
      page.select value, from: "lending_limit_#{attribute}"
    end
end
