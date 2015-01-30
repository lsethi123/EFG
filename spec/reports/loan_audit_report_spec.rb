require 'spec_helper'

describe LoanAuditReport do

  let!(:loan1) { FactoryGirl.create(:loan, :eligible, reference: 'ABC123') }

  let!(:loan2) { FactoryGirl.create(:loan, :guaranteed, reference: 'DEF456') }

  let!(:loan_state_change1) { FactoryGirl.create(:accepted_loan_state_change, loan: loan1) }

  let!(:loan_state_change2) { FactoryGirl.create(:guaranteed_loan_state_change, loan: loan2) }

  let(:loan_audit_report) { LoanAuditReport.new }

  describe "#count" do

    it "should return the total number of loans matching the report criteria" do
      expect(loan_audit_report.count).to eq(2)
    end

    it "should return the total number of loans with state guaranteed" do
      loan_audit_report.state = Loan::Guaranteed
      expect(loan_audit_report.count).to eq(1)
    end

  end

  describe "#loans" do

    it "should return all loans when matching the default report criteria" do
      expect(loan_audit_report.loans).to eq([loan1, loan2])
    end

    it "should return loans with a specific state" do
      loan_audit_report = LoanAuditReport.new(state: Loan::Guaranteed)
      expect(loan_audit_report.loans).to eq([ loan2 ])
    end

    it "should return loans for a specific lender" do
      loan_audit_report = LoanAuditReport.new(lender_id: loan1.lender_id)
      expect(loan_audit_report.loans).to eq([ loan1 ])
    end

    it "should return loans for a specific event" do
      loan_audit_report = LoanAuditReport.new(event_id: loan_state_change1.event_id)
      expect(loan_audit_report.loans).to eq([ loan1 ])
    end

    it "includes loans without a modified_by_legacy_id" do
      loan1.update_attribute(:modified_by_legacy_id, nil)

      loan_audit_report = LoanAuditReport.new
      expect(loan_audit_report.loans).to include(loan1)
    end

    context 'with initial draw' do
      let!(:loan1) { FactoryGirl.create(:loan, :guaranteed) }

      before(:each) do
        loan1.initial_draw_change.update_attribute(:date_of_change, 1.day.ago)
        loan2.initial_draw_change.update_attribute(:date_of_change, 1.day.from_now)
      end

      it "should return loans with an initial draw date after a specified date" do
        loan_audit_report = LoanAuditReport.new(facility_letter_start_date: Date.current.strftime('%d/%m/%Y'))
        expect(loan_audit_report.loans).to eq([ loan2 ])
      end

      it "should return loans with an initial draw date before a specified date" do
        loan_audit_report = LoanAuditReport.new(facility_letter_end_date: Date.current.strftime('%d/%m/%Y'))
        expect(loan_audit_report.loans).to eq([ loan1 ])
      end
    end

    it "should return loans with a created at date after a specified date" do
      loan1.update_attribute(:created_at, 1.day.ago)
      loan2.update_attribute(:created_at, 1.day.from_now)

      loan_audit_report = LoanAuditReport.new(created_at_start_date: Date.current.strftime('%d/%m/%Y'))

      expect(loan_audit_report.loans).to eq([ loan2 ])
    end

    it "should return loans with a created at date before a specified date" do
      loan1.update_attribute(:created_at, 1.day.ago)
      loan2.update_attribute(:created_at, 1.day.from_now)

      loan_audit_report = LoanAuditReport.new(created_at_end_date: Date.current.strftime('%d/%m/%Y'))

      expect(loan_audit_report.loans).to eq([ loan1 ])
    end

    it "should return loans last modified after the specified start date" do
      loan1.update_attribute(:last_modified_at, Time.new(2013, 02, 26, 23, 59, 59))
      loan2.update_attribute(:last_modified_at, Time.new(2013, 02, 28, 12,  0,  0))

      loan_audit_report = LoanAuditReport.new(last_modified_start_date: '27/02/2013')

      expect(loan_audit_report.loans).to eq([ loan2 ])
    end

    it "should return loans last modified before the specified end date" do
      loan1.update_attribute(:last_modified_at, Time.new(2013, 02, 26, 12,  0,  0))
      loan2.update_attribute(:last_modified_at, Time.new(2013, 02, 28,  0,  0,  0))

      loan_audit_report = LoanAuditReport.new(last_modified_end_date: '27/02/2013')

      expect(loan_audit_report.loans).to eq([ loan1 ])
    end

    it "should return loans with an audit record modified at date after a specified date" do
      loan_state_change1.update_attribute(:modified_at, 1.day.ago)
      loan_state_change2.update_attribute(:modified_at, 1.day.from_now)

      loan_audit_report = LoanAuditReport.new(audit_records_start_date: Date.current.strftime('%d/%m/%Y'))

      expect(loan_audit_report.loans).to eq([ loan2 ])
    end

    it "should return loans with an audit record modified at date before a specified date" do
      loan_state_change1.update_attribute(:modified_at, 1.day.ago)
      loan_state_change2.update_attribute(:modified_at, 1.day.from_now)

      loan_audit_report = LoanAuditReport.new(audit_records_end_date: Date.current.strftime('%d/%m/%Y'))

      expect(loan_audit_report.loans).to eq([ loan1 ])
    end

  end

  describe "#event_name" do
    it "returns 'All' with a nil event_id" do
      loan_audit_report.event_id = nil
      expect(loan_audit_report.event_name).to eq('All')
    end

    it "returns 'All' with a blank event_id" do
      loan_audit_report.event_id = ''
      expect(loan_audit_report.event_name).to eq('All')
    end

    it "returns event name with an event_id" do
      event = LoanEvent::NotProgressed
      loan_audit_report.event_id = event.id.to_s
      expect(loan_audit_report.event_name).to eq(event.name)
    end
  end

end
