# encoding: utf-8

require 'spec_helper'

describe 'loan guarantee' do
  let(:current_user) { FactoryGirl.create(:lender_user) }
  let(:loan) {
    FactoryGirl.create(:loan, :offered, :with_premium_schedule,
      lender: current_user.lender,
      repayment_duration: {years: 3},
      facility_letter_date: Date.new(2012, 10, 20)
    )
  }

  before { login_as(current_user, scope: :user) }

  it 'entering further loan information' do
    visit loan_path(loan)
    click_link 'Guarantee & Initial Draw'

    fill_in_valid_loan_guarantee_details(initial_draw_date: '30/11/2012')
    click_button 'Submit'

    loan = Loan.last!

    expect(current_path).to eq(loan_path(loan))

    expect(loan.state).to eq(Loan::Guaranteed)
    expect(loan.received_declaration).to eq(true)
    expect(loan.signed_direct_debit_received).to eq(true)
    expect(loan.first_pp_received).to eq(true)
    expect(loan.maturity_date).to eq(Date.new(2015, 11, 30))
    expect(loan.modified_by).to eq(current_user)

    should_log_loan_state_change(loan, Loan::Guaranteed, 7, current_user)

    loan_change = loan.initial_draw_change
    expect(loan_change.amount_drawn).to eq(loan.amount)
    expect(loan_change.change_type).to eq(nil)
    expect(loan_change.created_by).to eq(current_user)
    expect(loan_change.date_of_change).to eq(Date.new(2012, 11, 30))
    expect(loan_change.modified_date).to eq(Date.current)
    expect(loan_change.seq).to eq(0)
  end

  it 'does not continue with invalid values' do
    visit new_loan_guarantee_path(loan)

    expect(loan.state).to eq(Loan::Offered)
    expect {
      click_button 'Submit'
      loan.reload
    }.to_not change(loan, :state)

    expect(current_path).to eq("/loans/#{loan.id}/guarantee")
  end

  it 'allows you to change the lender reference' do
    Timecop.freeze(loan.facility_letter_date)

    visit loan_path(loan)
    click_link 'Guarantee & Initial Draw'

    fill_in_valid_loan_guarantee_details
    fill_in "Lender's Loan Reference", with: "MAH REF"
    click_button 'Submit'

    loan = Loan.last!
    expect(loan.lender_reference).to eq("MAH REF")

    Timecop.return
  end
end
