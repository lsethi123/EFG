require 'spec_helper'

describe LoanAuditReportCsvRow do

  describe "#row" do

    let(:user) { FactoryGirl.create(:user) }

    let!(:loan) {
      loan = FactoryGirl.create(
        :loan,
        reference: 'ABC123',
        amount: Money.new(500_000_00),
        maturity_date: Date.parse('28/05/2011'),
        cancelled_on: Date.parse('30/12/2012'),
        facility_letter_date: Date.parse('16/06/2012'),
        borrower_demanded_on: Date.parse('16/08/2012'),
        repaid_on: Date.parse('19/02/2014'),
        no_claim_on: Date.parse('13/08/2012'),
        dti_demanded_on: Date.parse('20/05/2011'),
        settled_on: Date.parse('03/07/2012'),
        remove_guarantee_on: Date.parse('24/04/2012'),
        generic1: 'Generic1',
        generic2: 'Generic2',
        generic3: 'Generic3',
        generic4: 'Generic4',
        generic5: 'Generic5',
        reason_id: 1,
        loan_category_id: LoanCategory::TypeB.id,
        loan_sub_category_id: 4,
        state: Loan::Guaranteed,
        created_at: Time.zone.parse('12/04/2012 14:34'),
        updated_at: Time.zone.parse('13/04/2012 14:34')
      )

      # stub custom fields that are created by LoanAuditReport SQL query
      loan.stub(
        lender_reference_code: 'DEF',
        loan_created_by: user.username,
        loan_modified_by: user.username,
        loan_state_change_to_state: Loan::AutoCancelled,
        loan_state_change_event_id: LoanEvent::Cancel.id,
        loan_state_change_modified_at: Time.parse('11/06/2012 11:00'),
        loan_state_change_modified_by: user.username,
        loan_initial_draw_date: Date.parse('03/06/2012')
      )

      loan
    }

    let(:row) { LoanAuditReportCsvRow.new(loan, 2, Loan::Offered).to_a }

    it 'should CSV data for loan' do
      expect(row[0]).to eq("ABC123")                       # loan_reference
      expect(row[1]).to eq("DEF")                          # lender_id
      expect(row[2]).to eq(Money.new(500_000_00).format)   # facility_amount
      expect(row[3]).to eq('28-05-2011')                   # maturity_date
      expect(row[4]).to eq('30-12-2012')                   # cancellation_date
      expect(row[5]).to eq('16-06-2012')                   # scheme_facility_letter_date
      expect(row[6]).to eq('03-06-2012')                   # initial_draw_date
      expect(row[7]).to eq('16-08-2012')                   # lender_demand_date
      expect(row[8]).to eq('19-02-2014')                   # repaid_date
      expect(row[9]).to eq('13-08-2012')                   # no_claim_date
      expect(row[10]).to eq('20-05-2011')                  # government_demand_date
      expect(row[11]).to eq('03-07-2012')                  # settled_date
      expect(row[12]).to eq('24-04-2012')                  # guarantee_remove_date
      expect(row[13]).to eq('Generic1')                    # generic1
      expect(row[14]).to eq('Generic2')                    # generic2
      expect(row[15]).to eq('Generic3')                    # generic3
      expect(row[16]).to eq('Generic4')                    # generic4
      expect(row[17]).to eq('Generic5')                    # generic5
      expect(row[18]).to eq(LoanReason.find(1).name)       # loan_reason
      expect(row[19]).to eq(LoanCategory::TypeB.name)      # loan_category
      expect(row[20]).to eq(LoanSubCategory.find(4).name)  # loan_sub_category
      expect(row[21]).to eq(Loan::Guaranteed.humanize)     # loan_state
      expect(row[22]).to eq('12-04-2012 02:34 PM')         # created_at
      expect(row[23]).to eq(user.username)                 # created_by
      expect(row[24]).to eq('13-04-2012 02:34 PM')         # modified_date
      expect(row[25]).to eq(user.username)                 # modified_by
      expect(row[26]).to eq("2")                           # audit_record_sequence
      expect(row[27]).to eq("Offered")                     # from_state
      expect(row[28]).to eq("Auto-cancelled")              # to_state
      expect(row[29]).to eq("Cancel loan")                 # loan_function
      expect(row[30]).to eq("11-06-2012 11:00 AM")         # audit_record_modified_at
      expect(row[31]).to eq(user.username)                 # audit_record_modified_by
    end

    it "should have 'Check eligibility' when loan_function is Accept" do
      loan.stub(loan_state_change_event_id: LoanEvent::Accept.id)

      expect(row[29]).to eq('Check eligibility')
    end

    it "should have 'Check eligibility' when loan_function is Reject" do
      loan.stub(loan_state_change_event_id: LoanEvent::Reject.id)

      expect(row[29]).to eq('Check eligibility')
    end
  end

end
