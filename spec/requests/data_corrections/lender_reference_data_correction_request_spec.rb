require 'spec_helper'

describe 'Lender Reference Data Correction' do
  include DataCorrectionSpecHelper

  let(:loan) { FactoryGirl.create(:loan, :guaranteed, lender: current_user.lender, lender_reference: 'LENDER SAYS') }

  before do
    visit_data_corrections
    click_link 'Lender Reference'
  end

  it do
    fill_in 'lender_reference', 'NEW REFERENCE'
    click_button 'Submit'

    data_correction = loan.data_corrections.last!
    expect(data_correction.change_type).to eq(ChangeType::LenderReference)
    expect(data_correction.created_by).to eq(current_user)
    expect(data_correction.date_of_change).to eq(Date.current)
    expect(data_correction.modified_date).to eq(Date.current)
    expect(data_correction.old_lender_reference).to eq('LENDER SAYS')
    expect(data_correction.lender_reference).to eq('NEW REFERENCE')

    loan.reload
    expect(loan.lender_reference).to eq('NEW REFERENCE')
    expect(loan.modified_by).to eq(current_user)
  end
end
