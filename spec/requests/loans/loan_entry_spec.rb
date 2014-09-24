# encoding: utf-8

require 'spec_helper'

describe 'loan entry' do
  let(:lender) { FactoryGirl.create(:lender) }
  let(:current_user) { FactoryGirl.create(:lender_user, lender: lender) }
  let(:lending_limit) { FactoryGirl.create(:lending_limit, phase_id: 5, lender: lender) }
  let(:loan) { FactoryGirl.create(:loan, lender: lender, loan_category_id: LoanCategory::TypeB.id, lending_limit: lending_limit) }

  before { login_as(current_user, scope: :user) }

  context 'Phase 6' do
    let(:lending_limit) { FactoryGirl.create(:lending_limit, phase_id: 6, lender: lender) }

    it 'can transition the loan to Complete' do
      visit loan_path(loan)
      click_link 'Loan Entry'

      fill_in_valid_loan_entry_details_phase_6(loan)
      click_button 'Submit'

      loan = Loan.last

      current_path.should == complete_loan_entry_path(loan)

      loan.state.should == Loan::Completed
      loan.declaration_signed.should be_true
      loan.business_name.should == 'Widgets Ltd.'
      loan.trading_name.should == 'Brilliant Widgets'
      loan.company_registration.should == '0123456789'
      loan.postcode.should == 'N8 4HF'
      loan.sortcode.should == '03-12-45'
      loan.lender_reference.should == 'lenderref1'
      loan.generic1.should == 'Generic 1'
      loan.generic2.should == 'Generic 2'
      loan.generic3.should == 'Generic 3'
      loan.generic4.should == 'Generic 4'
      loan.generic5.should == 'Generic 5'
      loan.interest_rate_type.should == InterestRateType.find(1)
      loan.interest_rate.should == 2.25
      loan.fees.should == Money.new(12345)
      loan.modified_by.should == current_user
      loan.state_aid.should == Money.new(794_98, 'EUR')

      should_log_loan_state_change(loan, Loan::Completed, 4, current_user)
    end
  end

  context 'Phase 5' do
    it 'can transition the loan to Complete' do
      visit loan_path(loan)
      click_link 'Loan Entry'

      fill_in_valid_loan_entry_details_phase_5(loan)
      click_button 'Submit'

      loan = Loan.last

      current_path.should == complete_loan_entry_path(loan)
      loan.state_aid.should == Money.new(3_098_74, 'EUR')
    end
  end

  it 'does not continue with invalid values' do
    visit new_loan_entry_path(loan)

    loan.state.should == Loan::Eligible
    expect {
      click_button 'Submit'
    }.not_to change(loan, :state)

    current_path.should == loan_entry_path(loan)
  end

  it 'saves the loan as Incomplete when it is invalid' do
    visit new_loan_entry_path(loan)

    click_button 'Save as Incomplete'

    loan.reload
    loan.state.should == Loan::Incomplete
    loan.modified_by.should == current_user

    current_path.should == loan_path(loan)
  end

  it 'progressing a loan from Incomplete to Completed' do
    loan.update_attribute(:state, Loan::Incomplete)
    visit loan_path(loan)
    click_link 'Loan Entry'

    fill_in_valid_loan_entry_details_phase_5(loan)

    click_button 'Submit'

    loan = Loan.last

    current_path.should == complete_loan_entry_path(loan)

    loan.state.should == Loan::Completed
    loan.modified_by.should == current_user
  end

  it 'should show specific questions for loan category B' do
    loan.update_attribute(:loan_category_id, LoanCategory::TypeB.id)

    visit new_loan_entry_path(loan)

    should_show_only_loan_category_fields(:loan_security_types, :security_proportion)
  end

  it 'should show specific questions for loan category C' do
    loan.update_attribute(:loan_category_id, LoanCategory::TypeC.id)

    visit new_loan_entry_path(loan)

    should_show_only_loan_category_fields(:original_overdraft_proportion, :refinance_security_proportion)
  end

  it 'should show specific questions for loan category D' do
    loan.update_attribute(:loan_category_id, LoanCategory::TypeD.id)

    visit new_loan_entry_path(loan)

    should_show_only_loan_category_fields(:refinance_security_proportion, :current_refinanced_amount, :final_refinanced_amount)
  end

  it 'should show specific questions for loan category E' do
    loan.update_attribute(:loan_category_id, LoanCategory::TypeE.id)

    visit new_loan_entry_path(loan)

    should_show_only_loan_category_fields(:overdraft_limit, :overdraft_maintained_true, :overdraft_maintained_false)
  end

  it 'should show specific questions for loan category F' do
    loan.update_attribute(:loan_category_id, LoanCategory::TypeF.id)

    visit new_loan_entry_path(loan)

    should_show_only_loan_category_fields(:invoice_discount_limit, :debtor_book_coverage, :debtor_book_topup)
  end

  it "should require recalculation of state aid when the loan repayment duration is changed" do
    visit new_loan_entry_path(loan)

    fill_in_valid_loan_entry_details_phase_5(loan)

    loan.reload
    loan.state_aid.should == Money.new(3_098_74, 'EUR')

    fill_in "loan_entry_repayment_duration_months", with: loan.repayment_duration.total_months + 12
    click_button 'Submit'

    page.should have_content("must be re-calculated when you change the loan term")

    calculate_state_aid(loan)

    click_button 'Submit'

    loan.reload
    loan.state_aid.should == Money.new(2_680_60, 'EUR')

    current_path.should == complete_loan_entry_path(loan)
  end

  context "when a sub-category is required" do
    it "should allow selection of sub-category" do
      visit new_loan_entry_path(loan)

      fill_in_valid_loan_entry_details_phase_5(loan)

      # switch to Category E
      select "Type E - Revolving Credit Guarantee", from: "loan_entry_loan_category_id"
      click_button 'Submit'

      select "Business Credit (or Charge) Cards", from: "loan_entry_loan_sub_category_id"
      fill_in 'loan_entry_overdraft_limit', with: '1000'
      choose 'loan_entry_overdraft_maintained_true'
      click_button 'Submit'

      current_path.should == complete_loan_entry_path(loan)

      loan.reload
      loan.loan_sub_category_id.should == 3
    end
  end

  context "with loan in sector with reduced state aid threshold" do
    let(:sic_code) { SicCode.find_by_code!(loan.sic_code) }

    before do
      sic_code.state_aid_threshold = Money.new(100_000_00, 'EUR')
      sic_code.save
    end

    it "shows the correct state aid threshold in question text" do
      visit new_loan_entry_path(loan)
      expected_amount = Money.new(100_000_00, 'EUR').format(no_cents: true)
      page.should have_content("no more than #{expected_amount}")
    end
  end

  private

    def should_show_only_loan_category_fields(*field_names)
      loan_category_fields = [
        :loan_security_types,
        :security_proportion,
        :original_overdraft_proportion,
        :refinance_security_proportion,
        :current_refinanced_amount,
        :final_refinanced_amount,
        :overdraft_limit,
        :overdraft_maintained,
        :invoice_discount_limit,
        :debtor_book_coverage,
        :debtor_book_topup
      ]

      field_names.all? do |field_name|
        page.should have_css("#loan_entry_#{field_name}")
      end

      (loan_category_fields - field_names).all? do |field_name|
        page.should_not have_css("#loan_entry_#{field_name}")
      end
    end

end
