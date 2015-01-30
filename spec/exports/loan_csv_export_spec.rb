require 'spec_helper'
require 'csv'

describe LoanCsvExport do
  describe '#generate' do
    let(:user) { FactoryGirl.create(:cfe_user, first_name: 'Joe', last_name: 'Bloggs') }
    let(:lender) { FactoryGirl.create(:lender, name: 'Little Tinkers') }
    let(:lending_limit) { FactoryGirl.create(:lending_limit, name: 'Lending Limit') }
    let(:sic) { loan.sic }
    let(:loan) {
      FactoryGirl.create(:loan, :completed, :guaranteed,
        created_by: user,
        lender: lender,
        lending_limit: lending_limit,
        maturity_date: Date.new(2022, 2, 22),
        reference: 'ABC2345-01',
        trading_date: Date.new(1999, 9, 9),
        lender_reference: 'lenderref1',
        dti_amount_claimed: Money.new(123_45),
        settled_amount: Money.new(100_00),
        loan_sub_category_id: 4
      )
    }
    let(:csv) {
      csv = LoanCsvExport.new(Loan.where(id: loan.id)).generate
      CSV.new(csv, { headers: :first_row })
    }

    let(:row) { csv.shift }
    let(:header) { row.headers }

    before do
      Timecop.freeze(2012, 10, 1, 16, 23, 45) do
        loan # Ensure created_at and initial_draw_date are known.
      end

      FactoryGirl.create(:loan_realisation, :pre,
        realised_amount: Money.new(300_00),
        realised_loan: loan
      )
      FactoryGirl.create(:loan_realisation, :post,
        realised_amount: Money.new(200_00),
        realised_loan: loan
      )
    end

    it 'should return csv data with one row of data' do
      expect(csv.to_a.size).to eq(1)
    end

    it 'should return csv data with correct header' do
      expect(header).to eq(%w(reference amount amount_demanded
        borrower_demanded_on sortcode business_name cancelled_comment
        cancelled_on cancelled_reason collateral_exhausted
        company_registration created_at created_by current_refinanced_amount
        debtor_book_coverage debtor_book_topup declaration_signed
        dti_break_costs dti_amount_claimed dti_ded_code
        dti_demand_outstanding dti_demanded_on dti_interest dti_reason
        facility_letter_date facility_letter_sent fees final_refinanced_amount
        first_pp_received generic1 generic2 generic3 generic4 generic5
        guarantee_rate guaranteed_on initial_draw_date initial_draw_amount
        interest_rate interest_rate_type invoice_discount_limit
        legacy_small_loan legal_form lender lending_limit loan_category
        loan_sub_category loan_scheme loan_source maturity_date next_borrower_demand_seq
        next_change_history_seq next_in_calc_seq next_in_realise_seq
        next_in_recover_seq no_claim_on non_val_postcode
        notified_aid original_overdraft_proportion
        outstanding_amount overdraft_limit overdraft_maintained
        personal_guarantee_required postcode premium_rate previous_borrowing
        private_residence_charge_required realised_money_date reason
        received_declaration recovery_on refinance_security_proportion
        remove_guarantee_on remove_guarantee_outstanding_amount
        remove_guarantee_reason repaid_on repayment_duration
        repayment_frequency security_proportion settled_on sic_code sic_desc
        sic_eligible sic_notified_aid sic_parent_desc
        signed_direct_debit_received standard_cap state state_aid
        state_aid_is_valid trading_date trading_name transferred_from
        turnover updated_at viable_proposition would_you_lend not_insolvent 
        lender_reference settled_amount cumulative_pre_claim_limit_realised_amount
        cumulative_post_claim_limit_realised_amount))
    end

    it 'should return correct csv data for loans' do
      expect(row['reference']).to eq('ABC2345-01')
      expect(row['amount']).to eq('12345.00')
      expect(row['amount_demanded']).to eq('')
      expect(row['borrower_demanded_on']).to eq('')
      expect(row['sortcode']).to eq('')
      expect(row['business_name']).to eq('Acme')
      expect(row['cancelled_comment']).to eq('')
      expect(row['cancelled_on']).to eq('')
      expect(row['cancelled_reason']).to eq('')
      expect(row['collateral_exhausted']).to eq('Yes')
      expect(row['company_registration']).to eq('')
      expect(row['created_at']).to eq('01/10/2012 16:23:45')
      expect(row['created_by']).to eq('Joe Bloggs')
      expect(row['current_refinanced_amount']).to eq('')
      expect(row['debtor_book_coverage']).to eq('')
      expect(row['debtor_book_topup']).to eq('')
      expect(row['declaration_signed']).to eq('')
      expect(row['dti_break_costs']).to eq('')
      expect(row['dti_amount_claimed']).to eq('123.45')
      expect(row['dti_ded_code']).to eq('')
      expect(row['dti_demand_outstanding']).to eq('')
      expect(row['dti_demanded_on']).to eq('')
      expect(row['dti_interest']).to eq('')
      expect(row['dti_reason']).to eq('')
      expect(row['facility_letter_date']).to eq('')
      expect(row['facility_letter_sent']).to eq('')
      expect(row['fees']).to eq('50000.00')
      expect(row['final_refinanced_amount']).to eq('')
      expect(row['first_pp_received']).to eq('Yes')
      expect(row['generic1']).to eq('')
      expect(row['generic2']).to eq('')
      expect(row['generic3']).to eq('')
      expect(row['generic4']).to eq('')
      expect(row['generic5']).to eq('')
      expect(row['guarantee_rate']).to eq('75.0')
      expect(row['guaranteed_on']).to eq('')
      expect(row['initial_draw_date']).to eq('01/10/2012')
      expect(row['initial_draw_amount']).to eq('10000.00')
      expect(row['interest_rate']).to eq('')
      expect(row['interest_rate_type']).to eq('')
      expect(row['invoice_discount_limit']).to eq('')
      expect(row['legacy_small_loan']).to eq('No')
      expect(row['legal_form']).to eq('Sole Trader')
      expect(row['lender']).to eq('Little Tinkers')
      expect(row['lending_limit']).to eq('Lending Limit')
      expect(row['loan_category']).to eq('Type A - New Term Loan with No Security')
      expect(row['loan_sub_category']).to eq('Bonds & Guarantees (Performance Bonds, VAT Deferment etc.)')
      expect(row['loan_scheme']).to eq('E')
      expect(row['loan_source']).to eq('S')
      expect(row['maturity_date']).to eq('22/02/2022')
      expect(row['next_borrower_demand_seq']).to eq('')
      expect(row['next_change_history_seq']).to eq('')
      expect(row['next_in_calc_seq']).to eq('')
      expect(row['next_in_realise_seq']).to eq('')
      expect(row['next_in_recover_seq']).to eq('')
      expect(row['no_claim_on']).to eq('')
      expect(row['non_val_postcode']).to eq('')
      expect(row['notified_aid']).to eq('0')
      expect(row['original_overdraft_proportion']).to eq('')
      expect(row['outstanding_amount']).to eq('')
      expect(row['overdraft_limit']).to eq('')
      expect(row['overdraft_maintained']).to eq('')
      expect(row['personal_guarantee_required']).to eq('No')
      expect(row['postcode']).to eq('EC1R 4RP')
      expect(row['premium_rate']).to eq('2.0')
      expect(row['previous_borrowing']).to eq('Yes')
      expect(row['private_residence_charge_required']).to eq('No')
      expect(row['realised_money_date']).to eq('')
      expect(row['reason']).to eq('Start-up costs')
      expect(row['received_declaration']).to eq('Yes')
      expect(row['recovery_on']).to eq('')
      expect(row['refinance_security_proportion']).to eq('')
      expect(row['remove_guarantee_on']).to eq('')
      expect(row['remove_guarantee_outstanding_amount']).to eq('')
      expect(row['remove_guarantee_reason']).to eq('')
      expect(row['repaid_on']).to eq('')
      expect(row['repayment_duration']).to eq('24')
      expect(row['repayment_frequency']).to eq('Monthly')
      expect(row['security_proportion']).to eq('')
      expect(row['settled_on']).to eq('')
      expect(row['sic_code']).to eq(sic.code)
      expect(row['sic_desc']).to eq(sic.description)
      expect(row['sic_eligible']).to eq('Yes')
      expect(row['sic_notified_aid']).to eq('')
      expect(row['sic_parent_desc']).to eq('')
      expect(row['signed_direct_debit_received']).to eq('Yes')
      expect(row['standard_cap']).to eq('')
      expect(row['state']).to eq('guaranteed')
      expect(row['state_aid']).to eq('10000.00')
      expect(row['state_aid_is_valid']).to eq('Yes')
      expect(row['trading_date']).to eq('09/09/1999')
      expect(row['trading_name']).to eq('Emca')
      expect(row['transferred_from']).to eq('')
      expect(row['turnover']).to eq('12345.00')
      expect(row['updated_at']).to eq('01/10/2012 16:23:45')
      expect(row['viable_proposition']).to eq('Yes')
      expect(row['would_you_lend']).to eq('Yes')
      expect(row['not_insolvent']).to eq('Yes')
      expect(row['lender_reference']).to eq('lenderref1')
      expect(row['settled_amount']).to eq('100.00')
      expect(row['cumulative_pre_claim_limit_realised_amount']).to eq('300.00')
      expect(row['cumulative_post_claim_limit_realised_amount']).to eq('200.00')
    end
  end
end
