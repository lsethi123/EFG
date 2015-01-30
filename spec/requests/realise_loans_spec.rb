require 'spec_helper'

describe 'Realise loans' do

  let(:current_user) { FactoryGirl.create(:cfe_user) }

  let!(:lender1) { FactoryGirl.create(:lender, name: 'Hayes Inc') }

  let!(:loan1) {
    FactoryGirl.create(:loan, :recovered,
                       reference: 'BSPFDNH-01',
                       lender_reference: 'lenderref1',
                       lender: lender1,
                       settled_on: Date.new(2009))
  }

  let!(:recovery1) { FactoryGirl.create(:recovery, loan: loan1, recovered_on: Date.new(2011, 2, 20)) }

  before(:each) do
    login_as(current_user, scope: :user)
    navigate_to_form
  end

  it 'should realise recovered loans' do
    # setup loans

    lender2 = FactoryGirl.create(:lender, name: 'Carroll-Cronin')

    loan2 = FactoryGirl.create(:loan, :recovered, reference: '3PEZRGB-01', lender: lender1, settled_on: Date.new(2009))
    loan3 = FactoryGirl.create(:loan, :recovered, reference: 'LOGIHLJ-02', lender: lender1, settled_on: Date.new(2009))
    loan5 = FactoryGirl.create(:loan, reference: 'HJD4JF8-01', lender: lender2, settled_on: Date.new(2009))
    loan6 = FactoryGirl.create(:loan, :recovered, reference: 'HJDS743-01', lender: lender1, settled_on: Date.new(2009))

    recovery2 = FactoryGirl.create(:recovery, loan: loan2, recovered_on: Date.new(2011, 2, 20))
    recovery3 = FactoryGirl.create(:recovery, loan: loan3, recovered_on: Date.new(2012, 5, 5))
    recovery5 = FactoryGirl.create(:recovery, loan: loan5, recovered_on: Date.new(2012, 5, 5))
    recovery6 = FactoryGirl.create(:recovery, loan: loan6, recovered_on: Date.new(2011, 2, 20))

    select_loans

    expect(page).to have_content('BSPFDNH-01')
    expect(page).to have_content('3PEZRGB-01')
    expect(page).to have_content('HJDS743-01')
    expect(page).not_to have_content('LOGIHLJ-02') # loan after quarter cut off date
    expect(page).not_to have_content('HJD4JF8-01') # loan belongs to different lender

    expect(page).to have_content('lenderref1')

    within "#realise_recovery_#{recovery1.id}" do
      find('input[type=checkbox][name$="[realised]"]').set(true)
    end

    within "#realise_recovery_#{recovery2.id}" do
      find('input[type=checkbox][name$="[realised]"]').set(true)
    end

    within "#realise_recovery_#{recovery6.id}" do
      find('input[type=checkbox][name$="[post_claim_limit]"]').set(true)
    end

    click_button 'Realise Loans'

    expect(page).to have_content('The following loans have been realised')
    expect(page).to have_content(loan1.reference)
    expect(page).to have_content(loan2.reference)
    expect(page).to have_content(loan2.reference)
    expect(page).to have_content(loan6.reference)
    expect(page).not_to have_content(loan3.reference)
    expect(page).not_to have_content(loan5.reference)

    expect(page).to have_content(loan1.lender_reference)

    loan1.reload
    expect(loan1.state).to eq(Loan::Realised)
    expect(loan1.modified_by).to eq(current_user)

    loan2.reload
    expect(loan2.state).to eq(Loan::Realised)
    expect(loan2.modified_by).to eq(current_user)

    loan6.reload
    expect(loan6.state).to eq(Loan::Realised)
    expect(loan6.modified_by).to eq(current_user)
    expect(loan6.loan_realisations.last.post_claim_limit).to eql(true)

    expect(loan3.reload.state).to eq(Loan::Recovered)
    expect(loan5.reload.state).to eq(Loan::Eligible)
  end

  it 'should validate select loans form' do
    click_button 'Select Loans'
    expect(page).to have_content("can't be blank")
  end

  it 'should validate loans have been selected' do
    select lender1.name, from: 'realisation_statement_received_lender_id'
    fill_in 'realisation_statement_received_reference', with: "ABC123"
    select 'March', from: 'realisation_statement_received_period_covered_quarter'
    fill_in 'realisation_statement_received_period_covered_year', with: '2011'
    fill_in 'realisation_statement_received_received_on', with: '20/05/2011'
    click_button 'Select Loans'

    click_button 'Realise Loans'

    expect(page).to have_content('No recoveries were selected.')
  end

  it 'should show error text when there are no loans to recover' do
    loan = FactoryGirl.create(:loan, :recovered, id: 1, recovery_on: Date.new(2011, 2, 20))

    navigate_to_form # go back to form so new loan record lender is in form
    select loan.lender.name, from: 'realisation_statement_received_lender_id'
    fill_in 'realisation_statement_received_reference', with: "ABC123"
    select 'March', from: 'realisation_statement_received_period_covered_quarter'
    fill_in 'realisation_statement_received_period_covered_year', with: '2010'
    fill_in 'realisation_statement_received_received_on', with: '20/05/2010'
    click_button 'Select Loans'

    expect(page).to have_content('There are no recoveries to realise.')
  end

  it 'can export loan data as CSV' do
    select_loans

    click_button "Export CSV"

    expect(page.current_url).to eq(select_loans_realise_loans_url(format: 'csv'))
  end

  private

  def select_loans
    select lender1.name, from: 'realisation_statement_received_lender_id'
    fill_in 'realisation_statement_received_reference', with: "ABC123"
    select 'March', from: 'realisation_statement_received_period_covered_quarter'
    fill_in 'realisation_statement_received_period_covered_year', with: '2011'
    fill_in 'realisation_statement_received_received_on', with: '20/05/2011'
    click_button 'Select Loans'
  end

  def navigate_to_form
    visit root_path
    click_link 'Recoveries Statement Received'
  end

end
