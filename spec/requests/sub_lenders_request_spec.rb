require 'spec_helper'

describe 'Sub-lenders' do
  let(:current_user) { FactoryGirl.create(:cfe_admin) }
  let!(:lender) { FactoryGirl.create(:lender, name: 'ACME') }

  before { login_as(current_user, scope: :user) }

  before do
    visit root_path
    click_link 'Manage Lenders'
  end

  describe 'creating new sub-lenders' do
    before do
      click_link 'Sub-lenders'
      click_link 'New Sub-lender'
    end

    it 'does not continue with invalid values' do
      fill_in 'name', ''

      click_button 'Create Sub-lender'

      page.should have_content("can't be blank")
      lender.sub_lenders.count.should be_zero
    end

    it 'adds sub-lender' do
      fill_in 'name', 'EMCA'

      click_button 'Create Sub-lender'

      current_path.should == lender_sub_lenders_path(lender)

      sub_lender = lender.sub_lenders.last
      sub_lender.name.should == 'EMCA'

      admin_audit = AdminAudit.last!
      admin_audit.action.should == AdminAudit::SubLenderCreated
      admin_audit.auditable.should == sub_lender
      admin_audit.modified_by.should == current_user
      admin_audit.modified_on.should == Date.current
    end
  end

  describe 'updating existing sub-lenders' do
    let!(:sub_lender) { FactoryGirl.create(:sub_lender, lender: lender, name: 'EMCA') }

    before do
      click_link 'Sub-lenders'
      click_link 'EMCA'
    end

    it 'does not continue with invalid values' do
      fill_in 'name', ''

      click_button 'Update Sub-lender'

      page.should have_content("can't be blank")
      lender.sub_lenders.first.name.should == 'EMCA'
    end

    it 'changes the sub-lender' do
      fill_in 'name', 'Foo'

      click_button 'Update Sub-lender'

      current_path.should == lender_sub_lenders_path(lender)

      sub_lender.reload
      sub_lender.name.should == 'Foo'

      admin_audit = AdminAudit.last!
      admin_audit.action.should == AdminAudit::SubLenderEdited
      admin_audit.auditable.should == sub_lender
      admin_audit.modified_by.should == current_user
      admin_audit.modified_on.should == Date.current
    end
  end

  describe 'delete sub-lender' do
    let!(:sub_lender) { FactoryGirl.create(:sub_lender, lender: lender) }

    before do
      click_link 'Sub-lenders'
    end

    it do
      click_link 'Delete'
      page.should_not have_content sub_lender.name
    end
  end

  private

  def fill_in(attribute, value)
    page.fill_in "sub_lender_#{attribute}", with: value
  end

end
