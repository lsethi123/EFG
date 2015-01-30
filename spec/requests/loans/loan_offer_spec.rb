# encoding: utf-8

require 'spec_helper'

describe 'loan offer' do
  let(:current_user) { FactoryGirl.create(:lender_user) }
  let(:lending_limit) { FactoryGirl.create(:lending_limit) }
  let(:loan) { FactoryGirl.create(:loan, :completed, :with_premium_schedule, lender: current_user.lender, lending_limit: lending_limit) }

  before { login_as(current_user, scope: :user) }

  def dispatch
    visit loan_path(loan)
    click_link 'Offer Scheme Facility'
  end

  it 'entering further loan information' do
    dispatch
    fill_in_valid_loan_offer_details(loan)
    click_button 'Submit'

    loan = Loan.last

    expect(current_path).to eq(loan_path(loan))

    expect(loan.state).to eq(Loan::Offered)
    expect(loan.facility_letter_date).to eq(Date.current)
    expect(loan.facility_letter_sent).to eq(true)
    expect(loan.modified_by).to eq(current_user)

    should_log_loan_state_change(loan, Loan::Offered, 5, current_user)
  end

  it 'does not continue with invalid values' do
    dispatch

    expect(loan.state).to eq(Loan::Completed)
    expect {
      click_button 'Submit'
      loan.reload
    }.to_not change(loan, :state)

    expect(current_path).to eq(loan_offer_path(loan))
  end

  context "with an unavailable lending limit" do
    let(:lending_limit) { FactoryGirl.create(:lending_limit, :inactive, lender: current_user.lender) }
    let!(:new_lending_limit) { FactoryGirl.create(:lending_limit, :active, lender: current_user.lender, name: 'The Next Great Lending Limit') }

    it "prompts to change the lending limit" do
      dispatch

      expect(page).to have_content 'Lending Limit Unavailable'

      select 'The Next Great Lending Limit', from: 'update_loan_lending_limit[new_lending_limit_id]'
      click_button 'Submit'

      loan.reload
      expect(loan.lending_limit).to eq(new_lending_limit)
      expect(loan.modified_by).to eq(current_user)
    end
  end

  context "when a premium schedule has not yet been generated" do
    let(:lending_limit) { FactoryGirl.create(:lending_limit, :phase_6) }
    let(:loan) { FactoryGirl.create(:loan, :completed, lender: current_user.lender, lending_limit: lending_limit) }

    it "redirects to the generate premium schedule form before progressing to loan offer form" do
      dispatch

      expected_text = I18n.t('premium_schedule.not_yet_generated')
      expect(page).to have_content(expected_text)

      page.fill_in :premium_schedule_initial_draw_year, with: '2014'
      click_button 'Submit'

      expect(page.current_url).to eq(new_loan_offer_url(loan))
    end
  end
end
