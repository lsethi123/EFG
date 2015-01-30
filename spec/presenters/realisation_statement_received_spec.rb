require 'spec_helper'

describe RealisationStatementReceived do
  describe "validations" do
    let(:realisation_statement_received) { FactoryGirl.build(:realisation_statement_received) }

    context "details" do
      it "must have a valid factory" do
        expect(realisation_statement_received).to be_valid
      end

      it "must have a lender" do
        realisation_statement_received.lender = nil
        expect(realisation_statement_received).not_to be_valid
      end

      it "must have a reference" do
        realisation_statement_received.reference = ''
        expect(realisation_statement_received).not_to be_valid
      end

      it "must have a period_covered_quarter" do
        realisation_statement_received.period_covered_quarter = ''
        expect(realisation_statement_received).not_to be_valid
      end

      it "must have a valid period_covered_quarter" do
        realisation_statement_received.period_covered_quarter = 'February'
        expect(realisation_statement_received).not_to be_valid
      end

      it "must have a period_covered_year" do
        realisation_statement_received.period_covered_year = ''
        expect(realisation_statement_received).not_to be_valid
      end

      it "must have a valid period_covered_year" do
        realisation_statement_received.period_covered_year = 'junk'
        expect(realisation_statement_received).not_to be_valid
      end

      it "must have a valid received_on" do
        realisation_statement_received.received_on = ''
        expect(realisation_statement_received).not_to be_valid
      end
    end

    context "save" do
      it "must have recoveries to be realised" do
        realisation_statement_received.recoveries.each do |recovery|
          recovery.realised = false
        end

        expect(realisation_statement_received).not_to be_valid(:save)
      end

      it "must have a creator" do
        expect {
          realisation_statement_received.creator = nil
          realisation_statement_received.valid?(:save)
        }.to raise_error(ActiveModel::StrictValidationFailed)
      end
    end
  end

  describe "#recoveries" do
    let(:realisation_statement_received) { FactoryGirl.build(:realisation_statement_received, period_covered_quarter: 'March', period_covered_year: '2012') }
    let(:loan) { FactoryGirl.create(:loan, lender: realisation_statement_received.lender, settled_on: Date.new(2010)) }

    let!(:specified_quarter_recovery) { FactoryGirl.create(:recovery, loan: loan, recovered_on: Date.new(2012, 3, 31)) }
    let!(:previous_quarter_recovery)  { FactoryGirl.create(:recovery, loan: loan, recovered_on: Date.new(2011, 12, 31)) }
    let!(:next_quarter_recovery)      { FactoryGirl.create(:recovery, loan: loan, recovered_on: Date.new(2012, 6, 30)) }

    it "should return recoveries within or prior to the specified quarter" do
      recoveries = realisation_statement_received.recoveries.map(&:recovery)

      expect(recoveries.size).to eq(2)
      expect(recoveries).to match_array([previous_quarter_recovery, specified_quarter_recovery])
    end

    it 'does not include recoveries from other lenders' do
      other_lender_recovery = FactoryGirl.create(:recovery, recovered_on: Date.new(2012))

      expect(realisation_statement_received.recoveries).not_to include(other_lender_recovery)
    end

    it 'does not include already realised recoveries' do
      already_recovered_recovery = FactoryGirl.create(:recovery, loan: loan, realise_flag: true)

      expect(realisation_statement_received.recoveries).not_to include(already_recovered_recovery)
    end
  end

  describe "#save" do
    let(:realisation_statement_received) { FactoryGirl.build(:realisation_statement_received, lender: lender) }
    let(:lender) { FactoryGirl.create(:lender) }

    context 'with valid loans to be realised' do
      let(:loan1) { FactoryGirl.create(:loan, :recovered, lender: lender, settled_on: Date.new(2000)) }
      let(:loan2) { FactoryGirl.create(:loan, :recovered, lender: lender, settled_on: Date.new(2000)) }
      let(:recovery1) { FactoryGirl.create(:recovery, loan: loan1, amount_due_to_dti: Money.new(123_00), recovered_on: Date.new(2006, 6)) }
      let(:recovery2) { FactoryGirl.create(:recovery, loan: loan2, amount_due_to_dti: Money.new(456_00), recovered_on: Date.new(2006, 6)) }
      let(:recovery3) { FactoryGirl.create(:recovery, loan: loan2, amount_due_to_dti: Money.new(789_00), recovered_on: Date.new(2006, 6)) }

      before do
        recoveries_to_realise_ids = [recovery1.id, recovery2.id, recovery3.id]
        realisation_statement_received.recoveries.select {|recovery| recoveries_to_realise_ids.include?(recovery.id)}.each do |recovery|
          recovery.realised = true
        end

        realisation_statement_received.save
      end

      it 'updates all loans to be realised to Realised state' do
        expect(loan1.reload.state).to eq(Loan::Realised)
        expect(loan2.reload.state).to eq(Loan::Realised)
      end

      it "logs the loan's state change" do
        expect(loan1.state_changes.where(state: 'realised', event_id: LoanEvent::RealiseMoney.id)).to exist
        expect(loan2.state_changes.where(state: 'realised', event_id: LoanEvent::RealiseMoney.id)).to exist
      end

      it 'updates recoveries to be realised' do
        expect(recovery1.reload.realise_flag).to eql(true)
        expect(recovery2.reload.realise_flag).to eql(true)
        expect(recovery3.reload.realise_flag).to eql(true)
      end

      it 'updates realised_money_date on all loans' do
        expect(loan1.reload.realised_money_date).to eq(Date.current)
        expect(loan2.reload.realised_money_date).to eq(Date.current)
      end

      it 'creates loan realisation for each recovery' do
        expect(LoanRealisation.count).to eq(3)
      end

      it 'creates loan realisations with the same created by user as the realisation statement' do
        realisation_statement = realisation_statement_received.realisation_statement
        realisation_statement_received.realisation_statement.loan_realisations.each do |loan_realisation|
          expect(loan_realisation.created_by).to eq(realisation_statement.created_by)
        end
      end

      it 'stores the realised amount on each new loan realisation' do
        realisation_statement = realisation_statement_received.realisation_statement
        realised_amounts = realisation_statement.loan_realisations.map(&:realised_amount)
        expect(realised_amounts).to match_array([Money.new(123_00), Money.new(456_00), Money.new(789_00)])
      end

      it 'associates the recoveries with the realisation statement' do
        realisation_statement = realisation_statement_received.realisation_statement
        expect(recovery1.reload.realisation_statement).to eq(realisation_statement)
        expect(recovery2.reload.realisation_statement).to eq(realisation_statement)
        expect(recovery3.reload.realisation_statement).to eq(realisation_statement)
      end
    end
  end
end
