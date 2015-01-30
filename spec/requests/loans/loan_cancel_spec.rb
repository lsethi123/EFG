require 'spec_helper'

describe 'loan cancel' do
  let(:current_user) { FactoryGirl.create(:lender_user) }
  let(:loan) { FactoryGirl.create(:loan, lender: current_user.lender) }
  before { login_as(current_user, scope: :user) }

  [
    Loan::Completed,
    Loan::Eligible,
    Loan::Incomplete,
    Loan::Offered
  ].each do |state|
    it "works from #{state} state" do
      loan.update_attribute :state, state

      visit loan_path(loan)
      click_link 'Cancel Loan'

      fill_in 'cancelled_on', Date.current.to_s(:screen)
      select CancelReason.find(4).name, from: 'loan_cancel_cancelled_reason_id'
      fill_in 'cancelled_comment', 'No comment'

      click_button 'Submit'

      loan = Loan.last
      expect(loan.state).to eq(Loan::Cancelled)
      expect(loan.cancelled_on).to eq(Date.current)
      expect(loan.cancelled_reason_id).to eq(4)
      expect(loan.cancelled_comment).to eq('No comment')
      expect(loan.modified_by).to eq(current_user)

      should_log_loan_state_change(loan, Loan::Cancelled, 3, current_user)
    end
  end

  it 'does not continue with invalid values' do
    visit loan_path(loan)
    click_link 'Cancel Loan'

    expect(loan.state).to eq(Loan::Eligible)
    expect {
      click_button 'Submit'
      loan.reload
    }.to_not change(loan, :state)

    expect(current_path).to eq(loan_cancel_path(loan))
  end

  private
  def choose_radio_button(attribute, value)
    choose "loan_cancel_#{attribute}_#{value}"
  end

  def fill_in(attribute, value)
    page.fill_in "loan_cancel_#{attribute}", with: value
  end
end
