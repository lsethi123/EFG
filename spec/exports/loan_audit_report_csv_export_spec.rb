require 'spec_helper'
require 'csv'

describe LoanAuditReportCsvExport do
  describe ".header" do
    let(:loan_audit_report_csv_export) { LoanAuditReportCsvExport.new(Loan.all) }

    let(:header) { CSV.parse(loan_audit_report_csv_export.first).first }

    it "should return array of strings with correct text" do
      expect(header[0]).to eq(t(:loan_reference))
      expect(header[1]).to eq(t(:lender_id))
      expect(header[2]).to eq(t(:facility_amount))
      expect(header[3]).to eq(t(:maturity_date))
      expect(header[4]).to eq(t(:cancellation_date))
      expect(header[5]).to eq(t(:scheme_facility_letter_date))
      expect(header[6]).to eq(t(:initial_draw_date))
      expect(header[7]).to eq(t(:lender_demand_date))
      expect(header[8]).to eq(t(:repaid_date))
      expect(header[9]).to eq(t(:no_claim_date))
      expect(header[10]).to eq(t(:government_demand_date))
      expect(header[11]).to eq(t(:settled_date))
      expect(header[12]).to eq(t(:guarantee_remove_date))
      expect(header[13]).to eq(t(:generic1))
      expect(header[14]).to eq(t(:generic2))
      expect(header[15]).to eq(t(:generic3))
      expect(header[16]).to eq(t(:generic4))
      expect(header[17]).to eq(t(:generic5))
      expect(header[18]).to eq(t(:loan_reason))
      expect(header[19]).to eq(t(:loan_category))
      expect(header[20]).to eq(t(:loan_sub_category))
      expect(header[21]).to eq(t(:loan_state))
      expect(header[22]).to eq(t(:created_at))
      expect(header[23]).to eq(t(:created_by))
      expect(header[24]).to eq(t(:modified_date))
      expect(header[25]).to eq(t(:modified_by))
      expect(header[26]).to eq(t(:audit_record_sequence))
      expect(header[27]).to eq(t(:from_state))
      expect(header[28]).to eq(t(:to_state))
      expect(header[29]).to eq(t(:loan_function))
      expect(header[30]).to eq(t(:audit_record_modified_date))
      expect(header[31]).to eq(t(:audit_record_modified_by))
    end
  end

  describe "#generate" do

    let!(:loan) { FactoryGirl.create(:loan) }

    let(:loan_audit_report_mock) { double(LoanAuditReportCsvRow, to_a: row_mock) }

    let(:loan_audit_report_csv_export) { LoanAuditReportCsvExport.new(Loan.all) }

    let(:row_mock) { Array.new(loan_audit_report_csv_export.fields.size) }

    let(:parsed_csv) { CSV.parse(loan_audit_report_csv_export.generate) }

    before(:each) do
      allow(loan_audit_report_csv_export).to receive(:csv_row).and_return(loan_audit_report_mock)
      allow_any_instance_of(Loan).to receive(:loan_state_change_to_state).and_return(Loan::Guaranteed)
    end

    it "should return a row for the header and each loan" do
      expect(parsed_csv.size).to eq(2)
    end
  end

  private

  def t(key)
    I18n.t(key, scope: 'csv_headers.loan_audit_report')
  end

end
