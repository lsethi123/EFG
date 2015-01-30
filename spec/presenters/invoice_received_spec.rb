require 'spec_helper'

describe InvoiceReceived do

  describe "validations" do
    let(:invoice_received) { FactoryGirl.build(:invoice_received) }

    context "details" do
      it "must have a valid factory" do
        expect(invoice_received).to be_valid
      end

      it "must have a lender" do
        invoice_received.lender = nil
        expect(invoice_received).not_to be_valid
      end

      it "must have a reference" do
        invoice_received.reference = ''
        expect(invoice_received).not_to be_valid
      end

      it "must have a period_covered_quarter" do
        invoice_received.period_covered_quarter = ''
        expect(invoice_received).not_to be_valid
      end

      it "must have a valid period_covered_quarter" do
        invoice_received.period_covered_quarter = 'February'
        expect(invoice_received).not_to be_valid
      end

      it "must have a period_covered_year" do
        invoice_received.period_covered_year = ''
        expect(invoice_received).not_to be_valid
      end

      it "must have a valid period_covered_year" do
        invoice_received.period_covered_year = 'junk'
        expect(invoice_received).not_to be_valid
      end

      it "must have a valid received_on" do
        invoice_received.received_on = ''
        expect(invoice_received).not_to be_valid
      end
    end

    context "save" do
      it "must have some loans" do
        invoice_received.loans_attributes = {}
        expect(invoice_received).not_to be_valid(:save)
      end

      it "must have a creator" do
        expect {
          invoice_received.creator = nil
          invoice_received.valid?(:save)
        }.to raise_error(ActiveModel::StrictValidationFailed)
      end
    end
  end

  describe "#loans" do
    let(:lender) { FactoryGirl.create(:lender) }
    let!(:demanded_loan_1) { FactoryGirl.create(:loan, :demanded, lender: lender) }
    let!(:demanded_loan_2) { FactoryGirl.create(:loan, :demanded, lender: lender) }
    let!(:settled_loan) { FactoryGirl.create(:loan, :settled, lender: lender) }
    let(:invoice_received) { FactoryGirl.build(:invoice_received, lender: lender) }

    it "returns SettleLoanRows for the lender's demanded loans" do
      invoice_received.loans.each do |loan|
        expect(loan).to be_instance_of(SettleLoan)
      end

      expect(invoice_received.loans.map(&:loan)).to match_array([demanded_loan_1, demanded_loan_2])
    end
  end

  describe "#save" do
    let(:creator) { FactoryGirl.create(:user) }
    let(:lender) { FactoryGirl.create(:lender) }
    let!(:demanded_loan_1) { FactoryGirl.create(:loan, :demanded, lender: lender) }
    let!(:demanded_loan_2) { FactoryGirl.create(:loan, :demanded, lender: lender) }
    let!(:demanded_loan_3) { FactoryGirl.create(:loan, :demanded, lender: lender) }
    let(:invoice_received) { FactoryGirl.build(:invoice_received, lender: lender) }

    before do
      invoice_received.lender = lender
      invoice_received.reference = 'X123'
      invoice_received.period_covered_quarter = 'March'
      invoice_received.period_covered_year = '2012'
      invoice_received.received_on = '22/01/2013'
      invoice_received.creator = creator

      invoice_received.loans_attributes = {
        '0' => {
          'id' => demanded_loan_1.id.to_s,
          'settled' => '1',
          'settled_amount' => '340.12'
        },
        '1' => {
          'id' => demanded_loan_2.id.to_s,
          'settled' => '1',
          'settled_amount' => '6234.45'
        },
        '2' => {
          'id' => demanded_loan_3.id.to_s,
          'settled' => '0'
        }
      }
    end

    it "creates a new invoice" do
      expect {
        invoice_received.save
      }.to change(Invoice, :count).by(1)

      invoice = Invoice.last
      expect(invoice.lender).to eq(lender)
      expect(invoice.reference).to eq('X123')
      expect(invoice.period_covered_quarter).to eq('March')
      expect(invoice.period_covered_year).to eq('2012')
      expect(invoice.received_on).to eq(Date.new(2013, 1, 22))
      invoice.created_by = creator
    end

    it "marks the selected loans as Settled" do
      Timecop.freeze(2013, 1, 22, 11, 49)

      invoice_received.save

      assert_loan_settled = ->(loan) do
        loan.reload

        expect(loan.state).to eq(Loan::Settled)
        expect(loan.settled_on).to eq(Date.new(2013, 1, 22))
        expect(loan.invoice).to eq(invoice_received.invoice)
        expect(loan.updated_at).to eq(Time.new(2013, 1, 22, 11, 49, 0))
        expect(loan.modified_by_id).to eq(creator.id)
      end

      assert_loan_settled.call(demanded_loan_1)
      assert_loan_settled.call(demanded_loan_2)

      demanded_loan_3.reload
      expect(demanded_loan_3.state).to eq(Loan::Demanded)
      expect(demanded_loan_3.settled_on).to be_nil
      expect(demanded_loan_3.invoice).to be_nil

      Timecop.return
    end

    it "updates the settled amount" do
      invoice_received.save

      demanded_loan_1.reload
      expect(demanded_loan_1.settled_amount).to eq(Money.new(340_12))

      demanded_loan_2.reload
      expect(demanded_loan_2.settled_amount).to eq(Money.new(6234_45))
    end

    it "logs the loan state changes" do
      expect {
        invoice_received.save
      }.to change(LoanStateChange, :count).by(2)
    end
  end

  describe "#lender_id" do
    let(:invoice_received) { FactoryGirl.build(:invoice_received) }

    it "returns the ID of the lender" do
      lender = FactoryGirl.create(:lender)
      invoice_received.lender = lender
      expect(invoice_received.lender_id).to eq(lender.id)
    end

    it "returns nil with no lender" do
      invoice_received.lender = nil
      expect(invoice_received.lender_id).to be_nil
    end
  end

  describe "#lender_id=" do
    let(:invoice_received) { FactoryGirl.build(:invoice_received) }

    it "sets the lender with the corresponding id" do
      lender = FactoryGirl.create(:lender)

      invoice_received.lender_id = lender.id
      expect(invoice_received.lender).to eq(lender)
    end

    it "sets the lender to nil with an incorrect id" do
      invoice_received.lender_id = 28
      expect(invoice_received.lender).to be_nil
    end

    it "sets the lender to nil when blank" do
      invoice_received.lender_id = ''
      expect(invoice_received.lender).to be_nil
    end
  end

  describe "#received_on=" do
    it "parses dates" do
      presenter = FactoryGirl.build(:invoice_received)
      presenter.received_on = '22/01/2013'
      expect(presenter.received_on).to eq(Date.new(2013, 1, 22))
    end
  end

end
