require 'spec_helper'
require 'csv'

describe LoanReportCsvExport do
  describe "#generate" do
    let!(:lender) { FactoryGirl.create(:lender, organisation_reference_code: 'ABC123') }
    let!(:user) { FactoryGirl.create(:lender_user, lender: lender) }

    let(:loan_report_presenter) { LoanReportPresenter.new(user) }

    before do
      loan_report_presenter.lender_ids = [lender.id]
      loan_report_presenter.states = Loan::States
      loan_report_presenter.loan_types = [LoanTypes::EFG.id]
    end

    let(:loan_report_csv_export) { LoanReportCsvExport.new(loan_report_presenter.loans) }
    let(:csv) { CSV.new(loan_report_csv_export.generate, { headers: :first_row }) }

    let(:user1) { FactoryGirl.create(:user, username: 'bobby.t') }
    let(:user2) { FactoryGirl.create(:user, username: 'billy.bob') }
    let(:ded_code) {
      FactoryGirl.create(:ded_code,
        category_description: 'Loss of Market',
        code: 'A.10.1.1',
        code_description: 'Competition',
        group_description: 'Trading'
      )
    }
    let!(:initial_draw_change) {
      FactoryGirl.create(:initial_draw_change,
        amount_drawn: Money.new(10_000_00),
        date_of_change: Date.new(2012, 5, 17),
        loan: loan
      )
    }
    let(:invoice) { FactoryGirl.create(:invoice, reference: '123-INV') }
    let(:lending_limit) {
      FactoryGirl.create(:lending_limit,
        lender: lender,
        name: 'lending limit',
        phase_id: 5
      )
    }
    let!(:loan_realisation_1) {
      FactoryGirl.create(:loan_realisation, :pre,
        created_at: Time.gm(2012, 8, 6),
        realised_amount: Money.new(3_000_00),
        realised_loan: loan
      )
    }
    let!(:loan_realisation_2) {
      FactoryGirl.create(:loan_realisation, :post,
        created_at: Time.gm(2012, 8, 6),
        realised_amount: Money.new(2_000_00),
        realised_loan: loan
      )
    }
    let!(:loan_security_1) {
      FactoryGirl.create(:loan_security,
        loan: loan,
        loan_security_type_id: 1
      )
    }
    let!(:loan_security_2) {
      FactoryGirl.create(:loan_security,
        loan: loan,
        loan_security_type_id: 2
      )
    }
    let!(:lump_sum_repayment) {
      FactoryGirl.create(:loan_change,
        loan: loan,
        amount_drawn: nil,
        lump_sum_repayment: Money.new(5_000_00)
      )
    }
    let!(:recovery) {
      FactoryGirl.create(:recovery,
        loan: loan,
        amount_due_to_dti: Money.new(150_000_00),
        recovered_on: Date.new(2012, 7, 18)
      )
    }

    let!(:loan) {
      FactoryGirl.create(:loan,
        ded_code: ded_code,
        invoice: invoice,
        lender: lender,
        lending_limit: lending_limit,
        reference: 'ABC12345',
        legal_form_id: 1,
        postcode: 'EC1V 3WB',
        turnover: 5000000,
        trading_date: Date.new(2011, 5, 28),
        sic_code: 1,
        sic_desc: 'Sic description',
        sic_parent_desc: 'Sic parent description',
        reason_id: 1,
        amount: 250000,
        guarantee_rate: 85.0,
        premium_rate: 3.0,
        state: 'eligible',
        repayment_duration: { months: 24 },
        repayment_frequency_id: 1,
        maturity_date: Date.new(2025, 11, 5),
        generic1: 'generic1',
        generic2: 'generic2',
        generic3: 'generic3',
        generic4: 'generic4',
        generic5: 'generic5',
        cancelled_reason_id: 1,
        cancelled_comment: 'cancel comment',
        cancelled_on: Date.new(2012, 1, 22),
        facility_letter_date: Date.new(2012, 5, 16),
        borrower_demanded_on: Date.new(2012, 6, 18),
        amount_demanded: 10000,
        repaid_on: Date.new(2012, 9, 15),
        no_claim_on: Date.new(2012, 9, 16),
        dti_demanded_on: Date.new(2012, 9, 17),
        dti_demand_outstanding: 50000,
        dti_amount_claimed: 40000,
        dti_interest: 5000,
        dti_reason: 'failure!',
        dti_break_costs: 5000,
        created_by: user1,
        created_at: Time.zone.local(2012, 4, 12, 14, 34),
        modified_by: user2,
        updated_at: Time.zone.local(2012, 4, 13, 0, 34),
        remove_guarantee_on: Date.new(2012, 9, 16),
        remove_guarantee_outstanding_amount: 20000,
        remove_guarantee_reason: 'removal reason',
        state_aid: 5600,
        settled_on: Date.new(2012, 7, 17),
        settled_amount: 1_000.00,
        loan_category_id: LoanCategory::TypeA.id,
        loan_sub_category_id: 4,
        interest_rate_type_id: 1,
        interest_rate: 2.0,
        fees: 5000,
        private_residence_charge_required: true,
        personal_guarantee_required: false,
        security_proportion: 70.0,
        current_refinanced_amount: 1000.00,
        final_refinanced_amount: 10000.00,
        original_overdraft_proportion: 60.0,
        refinance_security_proportion: 30.0,
        overdraft_limit: 5000,
        overdraft_maintained: true,
        invoice_discount_limit: 6000,
        debtor_book_coverage: 30,
        debtor_book_topup: 5,
        lender_reference: 'lenderref1',
      )
    }

    let(:row) { csv.shift }
    let(:header) { row.headers }

    it 'should return the correct headers' do
      expect(header).to eq(
        [
          :loan_reference,
          :legal_form,
          :post_code,
          :annual_turnover,
          :trading_date,
          :sic_code,
          :sic_code_description,
          :parent_sic_code_description,
          :purpose_of_loan,
          :facility_amount,
          :guarantee_rate,
          :premium_rate,
          :lending_limit,
          :lender_reference,
          :loan_state,
          :repayment_duration,
          :repayment_frequency,
          :maturity_date,
          :generic1,
          :generic2,
          :generic3,
          :generic4,
          :generic5,
          :cancellation_reason,
          :cancellation_comment,
          :cancellation_date,
          :scheme_facility_letter_date,
          :initial_draw_amount,
          :initial_draw_date,
          :lender_demand_date,
          :lender_demand_amount,
          :repaid_date,
          :no_claim_date,
          :demand_made_date,
          :outstanding_facility_principal,
          :total_claimed,
          :outstanding_facility_interest,
          :business_failure_group,
          :business_failure_category_description,
          :business_failure_description,
          :business_failure_code,
          :government_demand_reason,
          :break_cost,
          :latest_recovery_date,
          :total_recovered,
          :latest_realised_date,
          :total_realised,
          :cumulative_amount_drawn,
          :total_lump_sum_repayments,
          :created_by,
          :created_at,
          :modified_by,
          :modified_date,
          :guarantee_remove_date,
          :outstanding_balance,
          :guarantee_remove_reason,
          :state_aid_amount,
          :settled_date,
          :invoice_reference,
          :loan_category,
          :loan_sub_category,
          :interest_type,
          :interest_rate,
          :fees,
          :type_a1,
          :type_a2,
          :type_b1,
          :type_d1,
          :type_d2,
          :type_c1,
          :security_type,
          :type_c_d1,
          :type_e1,
          :type_e2,
          :type_f1,
          :type_f2,
          :type_f3,
          :loan_lender_reference,
          :settled_amount,
          :cumulative_pre_claim_limit_realised_amount,
          :cumulative_post_claim_limit_realised_amount,
          :scheme,
          :phase,
        ].map {|h| t(h) }
      )
    end

    it 'should return the correct data' do
      expect(row[t(:loan_reference)]).to eq("ABC12345")
      expect(row[t(:legal_form)]).to eq(LegalForm.find(1).name)
      expect(row[t(:post_code)]).to eq('EC1V 3WB')
      expect(row[t(:annual_turnover)]).to eq('5000000.00')
      expect(row[t(:trading_date)]).to eq('28-05-2011')
      expect(row[t(:sic_code)]).to eq('1')
      expect(row[t(:sic_code_description)]).to eq('Sic description')
      expect(row[t(:parent_sic_code_description)]).to eq('Sic parent description')
      expect(row[t(:purpose_of_loan)]).to eq(LoanReason.find(1).name)
      expect(row[t(:facility_amount)]).to eq('250000.00')
      expect(row[t(:guarantee_rate)]).to eq('85.0')
      expect(row[t(:premium_rate)]).to eq('3.0')
      expect(row[t(:lending_limit)]).to eq('lending limit')
      expect(row[t(:lender_reference)]).to eq('ABC123')
      expect(row[t(:loan_state)]).to eq('Eligible')
      expect(row[t(:repayment_duration)]).to eq('24')
      expect(row[t(:repayment_frequency)]).to eq(RepaymentFrequency.find(1).name)
      expect(row[t(:maturity_date)]).to eq('05-11-2025')
      expect(row[t(:generic1)]).to eq('generic1')
      expect(row[t(:generic2)]).to eq('generic2')
      expect(row[t(:generic3)]).to eq('generic3')
      expect(row[t(:generic4)]).to eq('generic4')
      expect(row[t(:generic5)]).to eq('generic5')
      expect(row[t(:cancellation_reason)]).to eq(CancelReason.find(1).name)
      expect(row[t(:cancellation_comment)]).to eq('cancel comment')
      expect(row[t(:cancellation_date)]).to eq('22-01-2012')
      expect(row[t(:scheme_facility_letter_date)]).to eq('16-05-2012')
      expect(row[t(:initial_draw_amount)]).to eq("10000.00")
      expect(row[t(:initial_draw_date)]).to eq('17-05-2012')
      expect(row[t(:lender_demand_date)]).to eq('18-06-2012')
      expect(row[t(:lender_demand_amount)]).to eq("10000.00")
      expect(row[t(:repaid_date)]).to eq('15-09-2012')
      expect(row[t(:no_claim_date)]).to eq('16-09-2012')
      expect(row[t(:demand_made_date)]).to eq('17-09-2012')
      expect(row[t(:outstanding_facility_principal)]).to eq("50000.00")
      expect(row[t(:total_claimed)]).to eq("40000.00")
      expect(row[t(:outstanding_facility_interest)]).to eq("5000.00")
      expect(row[t(:business_failure_group)]).to eq('Trading')
      expect(row[t(:business_failure_category_description)]).to eq('Loss of Market')
      expect(row[t(:business_failure_description)]).to eq('Competition')
      expect(row[t(:business_failure_code)]).to eq('A.10.1.1')
      expect(row[t(:government_demand_reason)]).to eq('failure!')
      expect(row[t(:break_cost)]).to eq("5000.00")
      expect(row[t(:latest_recovery_date)]).to eq('18-07-2012')
      expect(row[t(:total_recovered)]).to eq("150000.00")
      expect(row[t(:latest_realised_date)]).to eq('06-08-2012')
      expect(row[t(:total_realised)]).to eq('5000.00')
      expect(row[t(:cumulative_amount_drawn)]).to eq("10000.00")
      expect(row[t(:total_lump_sum_repayments)]).to eq("5000.00")
      expect(row[t(:created_by)]).to eq('bobby.t')
      expect(row[t(:created_at)]).to eq('12-04-2012 02:34 PM')
      expect(row[t(:modified_by)]).to eq('billy.bob')
      expect(row[t(:modified_date)]).to eq('13-04-2012')
      expect(row[t(:guarantee_remove_date)]).to eq('16-09-2012')
      expect(row[t(:outstanding_balance)]).to eq('20000.00')
      expect(row[t(:guarantee_remove_reason)]).to eq('removal reason')
      expect(row[t(:state_aid_amount)]).to eq('5600.00')
      expect(row[t(:settled_date)]).to eq('17-07-2012')
      expect(row[t(:invoice_reference)]).to eq('123-INV')
      expect(row[t(:loan_category)]).to eq(LoanCategory::TypeA.name)
      expect(row[t(:loan_sub_category)]).to eq(LoanSubCategory.find(4).name)
      expect(row[t(:interest_type)]).to eq(InterestRateType.find(1).name)
      expect(row[t(:interest_rate)]).to eq('2.0')
      expect(row[t(:fees)]).to eq('5000.00')
      expect(row[t(:type_a1)]).to eq('Yes')
      expect(row[t(:type_a2)]).to eq('No')
      expect(row[t(:type_b1)]).to eq('70.0')
      expect(row[t(:type_d1)]).to eq('1000.00')
      expect(row[t(:type_d2)]).to eq('10000.00')
      expect(row[t(:type_c1)]).to eq('60.0')
      expect(row[t(:security_type)]).to eq('Residential property other than a principal private residence / Commercial property') # security_type
      expect(row[t(:type_c_d1)]).to eq('30.0')
      expect(row[t(:type_e1)]).to eq('5000.00')
      expect(row[t(:type_e2)]).to eq('Yes')
      expect(row[t(:type_f1)]).to eq('6000.00')
      expect(row[t(:type_f2)]).to eq('30.0')
      expect(row[t(:type_f3)]).to eq('5.0')
      expect(row[t(:loan_lender_reference)]).to eq('lenderref1')
      expect(row[t(:settled_amount)]).to eq('1000.00')
      expect(row[t(:cumulative_pre_claim_limit_realised_amount)]).to eq('3000.00')
      expect(row[t(:cumulative_post_claim_limit_realised_amount)]).to eq('2000.00')
      expect(row[t(:scheme)]).to eq('EFG')
      expect(row[t(:phase)]).to eq('Phase 5 (FY 2013/14)')
    end

    context "without guarantee rate on loan" do
      before do
        loan.update_attribute(:guarantee_rate, nil)
      end

      it "exports phase's premium rate" do
        expect(row[t(:guarantee_rate)]).to eq('75.0')
      end
    end

    context "without premium rate on loan" do
      before do
        loan.update_attribute(:premium_rate, nil)
      end

      it "exports phase's premium rate" do
        expect(row[t(:premium_rate)]).to eq('2.0')
      end
    end  
  end

  private

  def t(key)
    I18n.t(key, scope: 'csv_headers.loan_report')
  end

end
