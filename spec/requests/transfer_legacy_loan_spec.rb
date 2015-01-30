require 'spec_helper'

describe 'Transfer a legacy loan' do
  let(:lender) { FactoryGirl.create(:lender, :with_lending_limit) }
  let(:current_user) { FactoryGirl.create(:lender_user, lender: lender) }
  let(:loan) { FactoryGirl.create(:loan, :offered, :guaranteed, :with_premium_schedule, :legacy_sflg) }

  before(:each) do
    login_as(current_user, scope: :user)
    visit root_path
    click_link 'Transfer a Legacy Loan'
  end

  it 'should transfer legacy loan from one lender to another' do
    fill_in 'loan_transfer_legacy_sflg_reference', with: loan.reference
    fill_in 'loan_transfer_legacy_sflg_amount', with: loan.amount.to_s
    fill_in 'loan_transfer_legacy_sflg_initial_draw_date', with: loan.initial_draw_change.date_of_change.to_s(:screen)
    fill_in 'loan_transfer_legacy_sflg_new_amount', with: loan.amount - Money.new(500)
    choose 'loan_transfer_legacy_sflg_declaration_signed_true'

    click_button 'Transfer Loan'

    expect(page).to have_content('This page provides confirmation that the loan has been transferred.')

    # Check original loan and new loan
    loan.reload
    expect(loan.state).to eq(Loan::RepaidFromTransfer)
    expect(loan.modified_by).to eq(current_user)

    transferred_loan = Loan.last
    expect(transferred_loan.transferred_from_id).to eq(loan.id)
    expect(transferred_loan.reference).to eq(loan.reference + '-02')
    expect(transferred_loan.state).to eq(Loan::Incomplete)
    expect(transferred_loan.business_name).to eq(loan.business_name)
    expect(transferred_loan.amount).to eq(loan.amount - Money.new(500))
    expect(transferred_loan.created_by).to eq(current_user)
    expect(transferred_loan.modified_by).to eq(current_user)

    # verify correct loan entry form is shown
    click_link 'Loan Entry'
    expect(current_path).to eq(new_loan_transferred_entry_path(transferred_loan))
  end

end
