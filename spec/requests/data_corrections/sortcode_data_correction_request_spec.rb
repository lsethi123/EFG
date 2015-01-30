require 'spec_helper'

describe 'Sortcode Data Correction' do
  include DataCorrectionSpecHelper

  let(:loan) { FactoryGirl.create(:loan, :guaranteed, lender: current_user.lender, sortcode: '123456') }

  before do
    visit_data_corrections
    click_link 'Sortcode'
  end

  it do
    fill_in 'sortcode', '654321'
    click_button 'Submit'

    data_correction = loan.data_corrections.last!
    expect(data_correction.change_type).to eq(ChangeType::DataCorrection)
    expect(data_correction.created_by).to eq(current_user)
    expect(data_correction.date_of_change).to eq(Date.current)
    expect(data_correction.modified_date).to eq(Date.current)
    expect(data_correction.old_sortcode).to eq('123456')
    expect(data_correction.sortcode).to eq('654321')

    loan.reload
    expect(loan.sortcode).to eq('654321')
    expect(loan.modified_by).to eq(current_user)
  end
end
