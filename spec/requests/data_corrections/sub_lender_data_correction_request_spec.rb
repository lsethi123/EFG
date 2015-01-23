require 'spec_helper'

describe 'Sub Lender Data Correction' do
  include DataCorrectionSpecHelper

  let!(:loan) { FactoryGirl.create(:loan, :guaranteed, lender: current_user.lender) }

  context "lender has sub-lenders" do
    let!(:sub_lender) { FactoryGirl.create(:sub_lender, lender: loan.lender) }
    let!(:old_value) { "old sub-lender" }
    let!(:new_value) { sub_lender.name }

    before do
      loan.update_column(:sub_lender, old_value)
      visit_data_corrections
      click_link "Sub-lender"
    end

    it do
      click_button 'Submit'
      page.should have_content "old sub-lender"
      page.should have_content "a sub-lender must be chosen"

      select new_value, from: 'data_correction_sub_lender'
      click_button 'Submit'

      data_correction = loan.data_corrections.last!
      data_correction.change_type.should == ChangeType::SubLender
      data_correction.created_by.should == current_user
      data_correction.date_of_change.should == Date.current
      data_correction.modified_date.should == Date.current
      data_correction.old_sub_lender.should == old_value
      data_correction.sub_lender.should == new_value

      loan.reload
      loan.sub_lender.should == new_value
      loan.modified_by.should == current_user
    end
  end

  context "lender has no sub-lenders and loan has no existing sub-lender" do
    it "does not show link to Sub-lender data correction" do
      visit_data_corrections
      page.should_not have_css('a', text: 'Sub-lender')
    end
  end
end
