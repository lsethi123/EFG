require 'spec_helper'

RSpec::Matchers.define :have_detail_row do |name, value|
  match do |page|
    expect(page).to have_xpath("//tr[th[text()='#{name}']][td[text()='#{value}']]")
  end
end

describe 'making a realisation adjustment' do
  let(:current_user) { FactoryGirl.create(:cfe_user) }
  before { login_as(current_user, scope: :user) }

  let!(:loan) { FactoryGirl.create(:loan, :realised) }
  let!(:realisation) { FactoryGirl.create(:loan_realisation, realised_loan: loan, realised_amount: Money.new(10_000_00)) }

  it do
    visit loan_path(loan)

    click_link 'Loan Details'
    page.should have_detail_row('Cumulative Value of All Pre-Claim Limit Realisations', '£10,000.00')
    page.should have_detail_row('Cumulative Value of All Realisations', '£10,000.00')

    click_link 'Make a Realisation Adjustment'

    fill_in 'Amount', with: '1,000.00'
    fill_in 'Date', with: '19/09/2014'
    fill_in 'Notes', with: 'Joe Bloggs informed us that this needed updating.'
    click_button 'Create Realisation Adjustment'

    click_link 'Loan Details'
    page.should have_detail_row('Cumulative Value of All Pre-Claim Limit Realisations', '£10,000.00')
    page.should have_detail_row('Cumulative Value of Realisation Adjustments', '£1,000.00')
    page.should have_detail_row('Cumulative Value of All Realisations', '£9,000.00')
  end

  # TODO: Non-realised loan doesn't have a button.
  # TODO: Validations fail test.
end
