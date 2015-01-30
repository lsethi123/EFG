require 'spec_helper'

describe 'Loan report' do

  let!(:loan1) { FactoryGirl.create(:loan, :eligible) }

  let!(:loan2) { FactoryGirl.create(:loan, :guaranteed) }

  before(:each) do
    login_as(current_user, scope: :user)
  end

  context 'as a lender user' do

    let(:lender) { loan1.lender }

    let(:current_user) { FactoryGirl.create(:lender_user, lender: lender) }

    it "should output a CSV report for that specific lender" do
      navigate_to_loan_report_form

      fill_in_valid_details
      click_button "Submit"

      expect(page).to have_content "Data extract found 1 row"

      click_button "Download Report"

      expect(page.response_headers['Content-Type']).to include('text/csv')
    end

    it "should only allow selection of loans created by any user belonging to that lender" do
      another_user = FactoryGirl.create(:lender_user, lender: loan1.lender, first_name: "Peter", last_name: "Parker")
      loan1.created_by = another_user
      loan1.save!

      navigate_to_loan_report_form

      loan1.lender.lender_users.each do |user|
        expect(page).to have_css("#loan_report_created_by_id option", text: user.name)
      end

      loan2.lender.lender_users.each do |another_lender_user|
        expect(page).not_to have_css("#loan_report_created_by_id option", text: another_lender_user.name)
      end

      fill_in_valid_details
      select "Peter Parker", from: "loan_report[created_by_id]"
      click_button "Submit"
      expect(page).to have_content "Data extract found 1 row"
    end

    it "shouldn't show lender selection'" do
      navigate_to_loan_report_form
      expect(page).not_to have_css('label[for=loan_report_lender_ids]')
    end

    context 'with "EFG only" loan scheme access' do
      before(:each) do
        lender.loan_scheme = Lender::EFG_SCHEME
        lender.save!
      end

      it 'should not allow selecting which loan schemes to report on' do
        navigate_to_loan_report_form
        expect(page).not_to have_css("#loan_report_loan_scheme")
      end
    end
  end

  context "as a CFE user" do

    let!(:loan3) { FactoryGirl.create(:loan) }

    let!(:current_user) { FactoryGirl.create(:cfe_user) }

    before(:each) do
      navigate_to_loan_report_form
    end

    it "should output a CSV report for a selection of lenders" do
      fill_in_valid_details

      select loan1.lender.name, from: "loan_report[lender_ids][]"
      select loan3.lender.name, from: "loan_report[lender_ids][]"

      click_button "Submit"

      expect(page).to have_content "Data extract found 2 rows"

      click_button "Download Report"

      expect(page.response_headers['Content-Type']).to include('text/csv')
    end

    it "should allow selection of 'All' lenders" do
      fill_in_valid_details

      select 'All', from: "loan_report[lender_ids][]"
      click_button "Submit"

      expect(page).to have_content "Data extract found 3 rows"
    end

    it "should not show created by form field" do
      expect(page).not_to have_css("#loan_report_created_by_id option")
    end

    it "should show validation errors" do
      click_button "Submit"

      # 2 errors - no lender selected, no loan type selected
      expect(page).to have_css('label[for=loan_report_lender_ids] + .controls .help-inline')
      expect(page).to have_css('input[name="loan_report[loan_types][]"] + .help-inline')
    end

  end

  context "as an Auditor user" do

    let!(:loan3) { FactoryGirl.create(:loan) }

    let!(:current_user) { FactoryGirl.create(:auditor_user) }

    before(:each) do
      navigate_to_loan_report_form
    end

    it "should allow access to loan reports" do
      navigate_to_loan_report_form
      expect(page).to have_css("#loan_report_facility_letter_start_date")
    end

    it "should not show created by form field" do
      navigate_to_loan_report_form
      expect(page).not_to have_css("#loan_report_created_by_id option")
    end

  end

  private

  def fill_in_valid_details
    select 'All states', from: 'loan_report[states][]'
    check :loan_report_loan_types_efg
  end

  def navigate_to_loan_report_form
    visit root_path
    click_link 'Generate a Loan Report'
  end

end
