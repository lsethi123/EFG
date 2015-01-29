require 'spec_helper'

describe 'making a realisation adjustment' do
  let(:current_user) { FactoryGirl.create(:cfe_user) }
  before { login_as(current_user, scope: :user) }

  let!(:loan) { FactoryGirl.create(:loan, :realised) }
  let!(:realisation) { FactoryGirl.create(:loan_realisation, realised_loan: loan, realised_amount: Money.new(10_000_00)) }

  it do
    visit loan_path(loan)
    click_link 'Make a Realisation Adjustment'

    fill_in 'Amount', with: '1000.00'
    fill_in 'Date', with: '19/09/2014'
    fill_in 'Notes', with: 'Joe Bloggs informed us that this needed updating.'
    click_button 'Submit'

    click_link 'Loan Details'
    page.should have_detail_row('Cumulative Value of All Pre-Claim Limit Realisations', '£10,000.00')
    page.should have_detail_row('Cumulative Value of Realisation Adjustments', '£1,000.00')
    page.should have_detail_row('Cumulative Value of All Realisations', '£9,000.00')
  end

  it "does not continue with invalid values" do
    visit new_loan_realisation_adjustment_path(loan)

    loan.state.should == Loan::Realised
    expect {
      click_button 'Submit'
      loan.reload
    }.to_not change(loan, :state)

    current_path.should == "/loans/#{loan.id}/realisation_adjustments"
  end
end
