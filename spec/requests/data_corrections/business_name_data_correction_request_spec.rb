require 'spec_helper'

describe 'Business Name Data Correction' do
  include DataCorrectionSpecHelper

  let(:loan) { FactoryGirl.create(:loan, :guaranteed, lender: current_user.lender, business_name: 'Foo') }

  before do
    visit_data_corrections
    click_link 'Business Name'
  end

  it do
    fill_in 'business_name', 'Bar'
    click_button 'Submit'

    data_correction = loan.data_corrections.last!
    expect(data_correction.change_type).to eq(ChangeType::BusinessName)
    expect(data_correction.created_by).to eq(current_user)
    expect(data_correction.date_of_change).to eq(Date.current)
    expect(data_correction.modified_date).to eq(Date.current)
    expect(data_correction.old_business_name).to eq('Foo')
    expect(data_correction.business_name).to eq('Bar')

    loan.reload
    expect(loan.business_name).to eq('Bar')
    expect(loan.modified_by).to eq(current_user)
  end
end
