require 'spec_helper'

describe 'Sub-lenders' do
  let(:current_user) { FactoryGirl.create(:cfe_admin) }
  let!(:lender) { FactoryGirl.create(:lender, name: 'ACME') }

  before { login_as(current_user, scope: :user) }

  before do
    visit root_path
    click_link 'Manage Lenders'
    click_link 'Sub-lenders'
  end

  describe 'creating new sub-lenders' do
    before do
      click_link 'New Sub-lender'
    end

    it 'does not continue with invalid values' do
      fill_in 'name', ''

      click_button 'Create Sub-lender'

      current_path.should == lender_lender_sub_lenders_path(lender)
    end

    it 'adds sub-lender' do
      fill_in 'name', 'EMCA'

      click_button 'Create Sub-lender'

      current_path.should == lender_sub_lenders_path(lender)

      lender.reload
      lender.sub_lenders.collect(&:name).should include('EMCA')
    end
  end

  describe 'updating existing sub-lenders' do
    let!(:sub_lender) { FactoryGirl.create(:sub_lender, lender: lender, name: 'EMCA') }

    before do
      click_link 'EMCA'
    end

    it 'does not continue with invalid values' do
      fill_in 'name', ''

      click_button 'Update Sub-lender'

      current_path.should == lender_sub_lender_path(sub_lender)
    end

    it 'changes the sub-lender' do
      fill_in 'name', 'Foo'

      click_button 'Update Sub-lender'

      current_path.should == lender_sub_lenders_path(lender)

      sub_lender.reload
      sub_lender.name.should eql('Foo')
    end
  end

  private

  def fill_in(attribute, value)
    page.fill_in "sub_lender_#{attribute}", with: value
  end

end
