require 'spec_helper'

describe "loan settled" do
  let(:current_user) { FactoryGirl.create(:cfe_user) }
  before { login_as(current_user, scope: :user) }

  context "with loans to settle" do
    let!(:lender1) { FactoryGirl.create(:lender, name: 'Hayes Inc') }
    let!(:lender2) { FactoryGirl.create(:lender, name: 'Carroll-Cronin') }

    let!(:loan1) {
      FactoryGirl.create(:loan, :demanded,
                         id: 1,
                         reference: 'BSPFDNH-01',
                         lender_reference: 'lenderref1',
                         lender: lender1)
    }
    let!(:loan2) { FactoryGirl.create(:loan, :demanded, id: 2, reference: '3PEZRGB-01', lender: lender1) }
    let!(:loan3) { FactoryGirl.create(:loan, :demanded, id: 3, reference: 'LOGIHLJ-02', lender: lender1) }
    let!(:loan4) { FactoryGirl.create(:loan, id: 4, reference: 'MF6XT4Z-01', lender: lender1) }
    let!(:loan5) { FactoryGirl.create(:loan, id: 5, reference: 'HJD4JF8-01', lender: lender2) }

    before(:each) do
      visit(root_path)
      click_link 'Invoice Received'
    end

    it 'can settle loans' do
      time = Time.zone.local(2012, 1, 7, 11, 00)

      # loans with data correction(s) are highlighted
      FactoryGirl.create(:data_correction, loan: loan2)

      Timecop.freeze(time) do
        fill_in_valid_details
        click_button 'Select Loans'

        page.should have_content('BSPFDNH-01')
        page.should have_content('3PEZRGB-01')
        page.should have_content('LOGIHLJ-02')
        page.should_not have_content('MF6XT4Z-01')
        page.should_not have_content('HJD4JF8-01')

        page.should have_content('lenderref1')

        page.should have_css("tr td:nth-child(2)", text: "*", count: 1)

        within('#settle_loan_1') do
          find('input[type=checkbox]').set(true)
        end

        within('#settle_loan_3') do
          find('input[type=checkbox]').set(true)
          find('input.currency').set('500.10')
        end

        click_button 'Settle Loans'
      end

      invoice = Invoice.last
      invoice.lender.should == lender1
      invoice.reference.should == '2006-SADHJ'
      invoice.period_covered_quarter.should == 'December'
      invoice.period_covered_year.should == '2011'
      invoice.received_on.should == Date.new(2012, 01, 06)
      invoice.created_by.should == current_user

      invoice.settled_loans.should =~ [loan1, loan3]

      loan1.reload
      loan1.state.should == Loan::Settled
      loan1.invoice.should == invoice
      loan1.modified_by.should == current_user
      loan1.settled_on.should == Date.new(2012, 01, 07)
      loan1.updated_at.to_i.should == time.to_i

      loan3.reload
      loan3.state.should == Loan::Settled
      loan3.invoice.should == invoice
      loan3.modified_by.should == current_user
      loan3.settled_on.should == Date.new(2012, 01, 07)
      loan3.updated_at.to_i.should == time.to_i
      loan3.settled_amount.should == Money.new(500_10)

      page.should have_content('BSPFDNH-01')
      page.should_not have_content('3PEZRGB-01')
      page.should have_content('LOGIHLJ-02')
      page.should_not have_content('MF6XT4Z-01')
      page.should_not have_content('HJD4JF8-01')

      page.should have_content('lenderref1')

      should_log_loan_state_change(loan1, Loan::Settled, 18, current_user)
      should_log_loan_state_change(loan3, Loan::Settled, 18, current_user)
    end

    it 'can export CSV' do
      fill_in_valid_details
      click_button 'Select Loans'
      click_button "Export CSV"
      page.current_url.should == select_loans_invoices_url(format: 'csv')
    end
  end

  it "validate the details" do
    visit(new_invoice_path)

    click_button 'Select Loans'

    page.should have_content('Name of the Lender submitting the invoice?')
    page.should have_content("What is the lender's invoice reference?")
    page.should have_content('What is the Demand Invoice Period quarter end date?')
    page.should have_content('What is the Demand Invoice Period quarter end year?')
    page.should have_content('On what date was the invoice received?')
  end

  it "validate loans have been selected" do
    lender1 = FactoryGirl.create(:lender, name: 'Hayes Inc')
    loan1 = FactoryGirl.create(:loan, :demanded, id: 1, reference: 'BSPFDNH-01', lender: lender1)

    visit(new_invoice_path)

    select 'Hayes Inc', from: 'invoice_received[lender_id]'
    fill_in 'invoice_received[reference]', with: '2006-SADHJ'
    select 'December', from: 'invoice_received[period_covered_quarter]'
    fill_in 'invoice_received[period_covered_year]', with: '2011'
    fill_in 'invoice_received[received_on]', with: '06/01/2012'

    click_button 'Select Loans'
    click_button 'Settle Loans'

    page.should have_content('No loans were selected.')
  end

  it "show text if there are no demanded loans" do
    FactoryGirl.create(:lender, name: 'Hayes Inc')

    visit(new_invoice_path)

    select 'Hayes Inc', from: 'invoice_received[lender_id]'
    fill_in 'invoice_received[reference]', with: '2006-SADHJ'
    select 'December', from: 'invoice_received[period_covered_quarter]'
    fill_in 'invoice_received[period_covered_year]', with: '2011'
    fill_in 'invoice_received[received_on]', with: '06/01/2012'

    click_button 'Select Loans'

    page.should have_content('There are no loans to settle.')
  end

  private

  def fill_in_valid_details
    select 'Hayes Inc', from: 'invoice_received[lender_id]'
    fill_in 'invoice_received[reference]', with: '2006-SADHJ'
    select 'December', from: 'invoice_received[period_covered_quarter]'
    fill_in 'invoice_received[period_covered_year]', with: '2011'
    fill_in 'invoice_received[received_on]', with: '06/01/2012'
  end

end
