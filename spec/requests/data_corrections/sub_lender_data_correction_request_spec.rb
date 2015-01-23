require 'spec_helper'

describe 'Sub Lender Data Correction' do
  include DataCorrectionSpecHelper

  context "lender has sub-lenders" do

    let!(:loan) { FactoryGirl.create(:loan, :guaranteed, lender: current_user.lender) }
    let!(:sub_lender) { FactoryGirl.create(:sub_lender, lender: loan.lender) }
    let!(:old_value) { loan.sub_lender }
    let!(:new_value) { sub_lender.name }

    before do
      visit_data_corrections
      click_link "Sub-lender"
    end

    it do
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
end
