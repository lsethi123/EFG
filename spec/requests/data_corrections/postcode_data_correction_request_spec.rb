require 'spec_helper'

describe 'Postcode Data Correction' do
  include DataCorrectionSpecHelper

  let(:loan) { FactoryGirl.create(:loan, :guaranteed, lender: current_user.lender, postcode: 'EC1R 4RP') }

  before do
    visit_data_corrections
    click_link 'Postcode'
  end

  it do
    fill_in 'postcode', 'EC1A 9PN'
    click_button 'Submit'

    data_correction = loan.data_corrections.last!
    expect(data_correction.change_type).to eq(ChangeType::Postcode)
    expect(data_correction.created_by).to eq(current_user)
    expect(data_correction.date_of_change).to eq(Date.current)
    expect(data_correction.modified_date).to eq(Date.current)
    expect(data_correction.old_postcode).to eq('EC1R 4RP')
    expect(data_correction.postcode).to eq('EC1A 9PN')

    loan.reload
    expect(loan.postcode).to eq('EC1A 9PN')
    expect(loan.modified_by).to eq(current_user)
  end
end
