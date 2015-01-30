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

    current_url.should == loan_eligibility_decision_url(loan.id)

    loan.lender.should == lender
    loan.state.should == Loan::Eligible
    expect(loan.viable_proposition).to eql(true)
    expect(loan.would_you_lend).to eql(true)
    expect(loan.collateral_exhausted).to eql(true)
    expect(loan.not_insolvent).to eql(true)
    loan.amount.should == Money.new(5000089)
    loan.lending_limit.should be_instance_of(LendingLimit)
    loan.repayment_duration.should == MonthDuration.new(30)
    loan.turnover.should == Money.new(123456789)
    loan.trading_date.should == Date.new(2012, 1, 31)
    loan.sic_code.should == sic_code.code
    loan.loan_category_id.should == LoanCategory::TypeB.id
    loan.reason_id.should == 28
    expect(loan.previous_borrowing).to eql(true)
    expect(loan.private_residence_charge_required).to eql(false)
    expect(loan.personal_guarantee_required).to eql(false)
    loan.loan_scheme.should == Loan::EFG_SCHEME
    loan.loan_source.should == Loan::SFLG_SOURCE
    loan.created_by.should == current_user
    loan.modified_by.should == current_user

    should_log_loan_state_change(loan, Loan::Eligible, 1, current_user)

    # email eligibility decision

    # with invalid email
    fill_in :eligibility_decision_email_email, with: 'wrong'
    click_button "Send"

    page.should have_content("is invalid")

    # with valid email
    fill_in :eligibility_decision_email_email, with: 'joe@example.com'
    click_button "Send"

    emails = ActionMailer::Base.deliveries
    emails.size.should == 1
    emails.first.to.should == [ 'joe@example.com' ]

    current_path.should == loan_path(loan)
    page.should have_content("Your email was sent successfully")
  end

  it 'does not create an invalid loan' do
    visit root_path
    click_link 'New Loan Application'

    expect {
      click_button 'Check'
    }.not_to change(Loan, :count)

    current_path.should == '/loans/eligibility_check'
  end

  it 'works for Type H loan category' do
    visit root_path
    click_link 'New Loan Application'

    fill_in_valid_eligibility_check_details(lender, sic_code)
    select LoanCategory.find(8).name, from: 'loan_eligibility_check_loan_category_id'

    expect {
      click_button 'Check'
    }.to change(Loan, :count)

    current_url.should == loan_eligibility_decision_url(Loan.last.id)
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

    current_url.should == loan_eligibility_decision_url(loan.id)

    loan.state.should == Loan::Rejected
    page.should have_content(I18n.t('validators.amount.amount.invalid', maximum: '£1,000,000.00', minimum: '£1,000.00'))

    # email eligibility decision

    fill_in :eligibility_decision_email_email, with: 'joe@example.com'
    click_button "Send"

    emails = ActionMailer::Base.deliveries
    emails.size.should == 1
    emails.first.to.should == [ 'joe@example.com' ]
    emails.first.body.should include(loan.ineligibility_reasons.first.reason)

    current_path.should == loan_path(loan)
    page.should have_content("Your email was sent successfully")
  end
end
