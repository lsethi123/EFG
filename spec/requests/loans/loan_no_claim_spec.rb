require 'spec_helper'

describe 'loan no claim' do
  let(:current_user) { FactoryGirl.create(:lender_user) }
  let(:loan) { FactoryGirl.create(:loan, :lender_demand, lender: current_user.lender) }
  before { login_as(current_user, scope: :user) }

  it 'progresses a loan to NotDemanded' do
    visit loan_path(loan)
    click_link 'No Claim'

    fill_in 'no_claim_on', '1/6/12'
    click_button 'Submit'

    loan = Loan.last

    expect(current_path).to eq(loan_path(loan))

    expect(loan.state).to eq(Loan::NotDemanded)
    expect(loan.no_claim_on).to eq(Date.new(2012, 6, 1))
    expect(loan.modified_by).to eq(current_user)

    should_log_loan_state_change(loan, Loan::NotDemanded, 11, current_user)
  end

  it 'does not continue with invalid values' do
    visit loan_path(loan)
    click_link 'No Claim'

    expect(loan.state).to eq(Loan::LenderDemand)
    expect {
      click_button 'Submit'
      loan.reload
    }.to_not change(loan, :state)

    expect(current_path).to eq(loan_no_claim_path(loan))
  end

  private
  def fill_in(attribute, value)
    page.fill_in "loan_no_claim_#{attribute}", with: value
  end
end
