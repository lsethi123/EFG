# encoding: utf-8

require 'spec_helper'

describe 'eligibility checks' do
  let(:lender) { FactoryGirl.create(:lender, :with_lending_limit) }
  let(:current_user) { FactoryGirl.create(:lender_user, lender: lender) }
  let!(:sic_code) { FactoryGirl.create(:sic_code) }

  before(:each) do
    ActionMailer::Base.deliveries.clear
    login_as(current_user, scope: :user)
  end

  it 'creates a loan from valid eligibility values' do
    visit root_path
    click_link 'New Loan Application'

    fill_in_valid_eligibility_check_details(lender, sic_code)

    expect {
      click_button 'Check'
    }.to change(Loan, :count).by(1)

    loan = Loan.last

    expect(current_url).to eq(loan_eligibility_decision_url(loan.id))

    expect(loan.lender).to eq(lender)
    expect(loan.state).to eq(Loan::Eligible)
    expect(loan.viable_proposition).to eql(true)
    expect(loan.would_you_lend).to eql(true)
    expect(loan.collateral_exhausted).to eql(true)
    expect(loan.not_insolvent).to eql(true)
    expect(loan.amount).to eq(Money.new(5000089))
    expect(loan.lending_limit).to be_instance_of(LendingLimit)
    expect(loan.repayment_duration).to eq(MonthDuration.new(30))
    expect(loan.turnover).to eq(Money.new(123456789))
    expect(loan.trading_date).to eq(Date.new(2012, 1, 31))
    expect(loan.sic_code).to eq(sic_code.code)
    expect(loan.loan_category_id).to eq(LoanCategory::TypeB.id)
    expect(loan.reason_id).to eq(28)
    expect(loan.previous_borrowing).to eql(true)
    expect(loan.private_residence_charge_required).to eql(false)
    expect(loan.personal_guarantee_required).to eql(false)
    expect(loan.loan_scheme).to eq(Loan::EFG_SCHEME)
    expect(loan.loan_source).to eq(Loan::SFLG_SOURCE)
    expect(loan.created_by).to eq(current_user)
    expect(loan.modified_by).to eq(current_user)

    should_log_loan_state_change(loan, Loan::Eligible, 1, current_user)

    # email eligibility decision

    # with invalid email
    fill_in :eligibility_decision_email_email, with: 'wrong'
    click_button "Send"

    expect(page).to have_content("is invalid")

    # with valid email
    fill_in :eligibility_decision_email_email, with: 'joe@example.com'
    click_button "Send"

    emails = ActionMailer::Base.deliveries
    expect(emails.size).to eq(1)
    expect(emails.first.to).to eq([ 'joe@example.com' ])

    expect(current_path).to eq(loan_path(loan))
    expect(page).to have_content("Your email was sent successfully")
  end

  it 'does not create an invalid loan' do
    visit root_path
    click_link 'New Loan Application'

    expect {
      click_button 'Check'
    }.not_to change(Loan, :count)

    expect(current_path).to eq('/loans/eligibility_check')
  end

  it 'works for Type H loan category' do
    visit root_path
    click_link 'New Loan Application'

    fill_in_valid_eligibility_check_details(lender, sic_code)
    select LoanCategory.find(8).name, from: 'loan_eligibility_check_loan_category_id'

    expect {
      click_button 'Check'
    }.to change(Loan, :count)

    expect(current_url).to eq(loan_eligibility_decision_url(Loan.last.id))
  end

  it 'displays ineligibility reasons for a reject loan' do
    visit root_path
    click_link 'New Loan Application'

    fill_in_valid_eligibility_check_details(lender, sic_code)
    # make loan fail eligibility check
    fill_in :loan_eligibility_check_amount, with: '6000000'

    expect {
      click_button 'Check'
    }.to change(Loan, :count).by(1)

    loan = Loan.last

    expect(current_url).to eq(loan_eligibility_decision_url(loan.id))

    expect(loan.state).to eq(Loan::Rejected)
    expect(page).to have_content(I18n.t('validators.amount.amount.invalid', maximum: '£1,000,000.00', minimum: '£1,000.00'))

    # email eligibility decision

    fill_in :eligibility_decision_email_email, with: 'joe@example.com'
    click_button "Send"

    emails = ActionMailer::Base.deliveries
    expect(emails.size).to eq(1)
    expect(emails.first.to).to eq([ 'joe@example.com' ])
    expect(emails.first.body).to include(loan.ineligibility_reasons.first.reason)

    expect(current_path).to eq(loan_path(loan))
    expect(page).to have_content("Your email was sent successfully")
  end
end
