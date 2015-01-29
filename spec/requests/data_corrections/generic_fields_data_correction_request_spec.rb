require 'spec_helper'

describe 'Generic Fields Data Correction' do

  include DataCorrectionSpecHelper

  let(:loan) { FactoryGirl.create(:loan, :guaranteed, lender: current_user.lender) }
  let!(:old_generic_value_1) { loan.generic1 }
  let!(:old_generic_value_2) { loan.generic2 }
  let!(:old_generic_value_3) { loan.generic3 }
  let!(:old_generic_value_4) { loan.generic4 }
  let!(:old_generic_value_5) { loan.generic5 }

  let!(:new_generic_value_1) { "our reference ab12" }
  let!(:new_generic_value_2) { "authorized" }
  let!(:new_generic_value_3) { "important loan info" }
  let!(:new_generic_value_4) { "entered by jeff" }
  let!(:new_generic_value_5) { "" }

  before do
    visit_data_corrections
    click_link "Generic Fields"
  end

  it do
    fill_in :generic1, new_generic_value_1
    fill_in :generic2, new_generic_value_2
    fill_in :generic3, new_generic_value_3
    fill_in :generic4, new_generic_value_4
    fill_in :generic5, new_generic_value_5

    click_button 'Submit'

    data_correction = loan.data_corrections.last!
    data_correction.change_type.should == ChangeType::GenericFields
    data_correction.created_by.should == current_user
    data_correction.date_of_change.should == Date.current
    data_correction.modified_date.should == Date.current

    data_correction.old_generic1.should == old_generic_value_1
    data_correction.old_generic2.should == old_generic_value_2
    data_correction.old_generic3.should == old_generic_value_3
    data_correction.old_generic4.should == old_generic_value_4
    data_correction.old_generic5.should == old_generic_value_5

    data_correction.generic1.should == new_generic_value_1
    data_correction.generic2.should == new_generic_value_2
    data_correction.generic3.should == new_generic_value_3
    data_correction.generic4.should == new_generic_value_4
    data_correction.generic5.should == new_generic_value_5

    loan.reload
    loan.generic1.should == new_generic_value_1
    loan.generic2.should == new_generic_value_2
    loan.generic3.should == new_generic_value_3
    loan.generic4.should == new_generic_value_4
    loan.generic5.should == new_generic_value_5
    loan.modified_by.should == current_user
  end

end
