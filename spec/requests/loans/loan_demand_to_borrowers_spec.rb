# encoding: utf-8

require 'spec_helper'

describe 'loan demand to borrower' do
  let(:current_lender) { FactoryGirl.create(:lender) }
  let(:current_user) { FactoryGirl.create(:lender_user, lender: current_lender) }
  let(:loan) { FactoryGirl.create(:loan, :guaranteed, lender: current_lender) }

  before do
    initial_draw_change = loan.initial_draw_change
    initial_draw_change.amount_drawn = loan.amount
    initial_draw_change.date_of_change = Date.new(2012)
    initial_draw_change.save!

    login_as(current_user, scope: :user)
  end

  it 'entering further loan information' do
    visit loan_path(loan)
    click_link 'Demand to Borrower'

    fill_in_valid_demand_to_borrower_details
    click_button 'Submit'

    loan = Loan.last

    expect(current_path).to eq(loan_path(loan))

    expect(loan.state).to eq(Loan::LenderDemand)
    expect(loan.borrower_demanded_on).to eq(Date.current)
    expect(loan.amount_demanded).to eq(Money.new(10_000_00)) # 10000.00
    expect(loan.modified_by).to eq(current_user)

    should_log_loan_state_change(loan, Loan::LenderDemand, 10, current_user)

    demand_to_borrower = loan.demand_to_borrowers.last!
    expect(demand_to_borrower.created_by).to eq(current_user)
    expect(demand_to_borrower.date_of_demand).to eq(Date.current)
    expect(demand_to_borrower.demanded_amount).to eq(Money.new(10_000_00))
    expect(demand_to_borrower.modified_date).to eq(Date.current)
  end

  it 'does not display previous DemandToBorrow details' do
    loan.update_attribute(:amount_demanded, 1234)

    visit loan_path(loan)
    click_link 'Demand to Borrower'
    expect(page.find('#loan_demand_to_borrower_amount_demanded').value).to be_blank
  end

  it 'does not continue with invalid values' do
    visit loan_path(loan)
    click_link 'Demand to Borrower'

    expect(loan.state).to eq(Loan::Guaranteed)
    expect {
      click_button 'Submit'
      loan.reload
    }.to_not change(loan, :state)

    expect(current_path).to eq(loan_demand_to_borrower_path(loan))
  end

end
