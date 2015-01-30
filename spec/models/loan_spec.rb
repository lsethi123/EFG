require 'spec_helper'

describe Loan do
  let(:loan) { FactoryGirl.build(:loan) }

  describe 'validations' do
    it 'has a valid Factory' do
      expect(loan).to be_valid
    end

    it 'strictly requires a lender' do
      expect {
        loan.lender = nil
        loan.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'requires a state' do
      expect {
        loan.state = nil
        loan.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'requires a known state' do
      expect {
        loan.state = 'not-a-known-state-yo'
        loan.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'requires a creator' do
      expect {
        loan.created_by_id = nil
        loan.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'requires a modifier' do
      expect {
        loan.modified_by_id = nil
        loan.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end
  end

  describe ".last_updated_between scope" do
    let!(:loan1) { FactoryGirl.create(:loan, updated_at: 3.days.ago) }
    let!(:loan2) { FactoryGirl.create(:loan, updated_at: 1.day.ago) }

    it "returns loans last updated between the specified dates" do
      expect(Loan.last_updated_between(2.days.ago, 1.day.ago)).to eq([loan2])
    end
  end

  describe ".not_progressed scope" do
    let!(:loan1) { FactoryGirl.create(:loan, :eligible) }
    let!(:loan2) { FactoryGirl.create(:loan, :completed) }
    let!(:loan3) { FactoryGirl.create(:loan, :incomplete) }
    let!(:loan4) { FactoryGirl.create(:loan, :offered) }

    it "returns loans with Eligible, Complete or Incomplete state" do
      result = Loan.not_progressed

      expect(result).to include(loan1)
      expect(result).to include(loan2)
      expect(result).to include(loan3)
      expect(result).not_to include(loan4)
    end
  end

  describe ".by_reference scope" do
    before(:each) do
      LoanReference.stub(:generate).and_return("ABC123", "ABC12345")
    end

    let!(:loan1) { FactoryGirl.create(:loan) }
    let!(:loan2) { FactoryGirl.create(:loan) }

    it "returns loans that partially or completely match the specified reference" do
      expect(Loan.by_reference("ABC123")).to eq([loan1, loan2])
    end
  end

  describe '.with_scheme' do
    let!(:loan1) { FactoryGirl.create(:loan, :efg) }
    let!(:loan2) { FactoryGirl.create(:loan, :sflg) }
    let!(:loan3) { FactoryGirl.create(:loan, :legacy_sflg) }

    context 'efg' do
      it do
        expect(Loan.with_scheme('efg')).to eq([loan1])
      end
    end

    context 'sflg' do
      it do
        expect(Loan.with_scheme('sflg')).to eq([loan2])
      end
    end

    context 'legacy_sflg' do
      it do
        expect(Loan.with_scheme('legacy_sflg')).to eq([loan3])
      end
    end

    context 'with an unknown scheme' do
      it do
        expect(Loan.with_scheme('foo')).to eq([])
      end
    end
  end

  describe "#premium_schedule" do

    let!(:loan) { FactoryGirl.create(:loan) }

    let!(:premium_schedule1) { FactoryGirl.create(:premium_schedule, loan: loan) }

    let!(:premium_schedule2) { FactoryGirl.create(:premium_schedule, loan: loan) }

    it "returns the most recent state aid calculation record" do
      expect(loan.premium_schedule).to eq(premium_schedule2)
    end
  end

  describe '#repayment_duration / #repayment_duration=' do
    let(:loan) { Loan.new }

    it 'conforms to the MonthDuration interface' do
      loan[:repayment_duration] = 18
      expect(loan.repayment_duration).to eq(MonthDuration.new(18))
    end

    it 'converts year/months hash to months' do
      loan.repayment_duration = { years: 1, months: 6 }
      expect(loan.repayment_duration).to eq(MonthDuration.new(18))
    end

    it 'does not convert blank values to zero' do
      loan.repayment_duration = { years: '', months: '' }
      expect(loan.repayment_duration).to be_nil
    end
  end

  describe "#state_aid" do
    it "should return a EUR money object" do
      loan = FactoryGirl.build(:loan, state_aid: '100.00')
      expect(loan.state_aid).to eq(Money.new(100_00, 'EUR'))
    end

    it "return nil if not set" do
      loan = FactoryGirl.build(:loan, state_aid: '')
      expect(loan.state_aid).to be_nil
    end
  end

  describe "reference" do
    let(:loan) {
      loan = FactoryGirl.build(:loan)
      loan.reference = nil
      loan
    }

    it "should be generated when loan is created" do
      expect(loan.reference).to be_nil

      loan.save!

      expect(loan.reference).to be_instance_of(String)
    end

    it "should be unique" do
      FactoryGirl.create(:loan, reference: 'ABC234')
      FactoryGirl.create(:loan, reference: 'DEF456')
      LoanReference.stub(:generate).and_return('ABC234', 'DEF456', 'GHF789')

      loan.save!

      expect(loan.reference).to eq('GHF789')
    end

    it "should not be generated if already assigned" do
      loan.reference = "custom-reference"
      loan.save!
      expect(loan.reload.reference).to eq('custom-reference')
    end
  end

  describe "#already_transferred" do
    it "returns true when a loan with the next incremented loan reference exists" do
      FactoryGirl.create(:loan, reference: 'Q9HTDF7-02')

      expect(FactoryGirl.build(:loan, reference: 'Q9HTDF7-01')).to be_already_transferred
    end

    it "returns false when loan with next incremented loan reference does not exist" do
      expect(FactoryGirl.build(:loan, reference: 'Q9HTDF7-01')).not_to be_already_transferred
    end

    it "returns false when loan has no reference" do
      expect(Loan.new).not_to be_already_transferred
    end
  end

  describe "#created_from_transfer?" do
    it "returns true when a loan has been transferred from another loan" do
      loan = FactoryGirl.build(:loan, reference: 'Q9HTDF7-02')
      expect(loan).to be_created_from_transfer
    end

    it "returns false when loan with next incremented loan reference does not exist" do
      loan = FactoryGirl.build(:loan, reference: 'Q9HTDF7-01')
      expect(loan).not_to be_created_from_transfer
    end

    it "returns false when loan has no reference" do
      expect(Loan.new).not_to be_created_from_transfer
    end
  end

  describe '#cumulative_drawn_amount' do
    before do
      loan.save!
    end

    it 'sums amount_drawn' do
      FactoryGirl.create(:initial_draw_change, loan: loan, amount_drawn: Money.new(123_45))
      FactoryGirl.create(:loan_change, loan: loan, amount_drawn: Money.new(678_90), change_type: ChangeType::RecordAgreedDraw)

      expect(loan.cumulative_drawn_amount).to eq(Money.new(802_35))
    end
  end

  describe '#cumulative_pre_claim_limit_realised_amount' do
    context 'with loan_realisations' do
      before do
        loan.save!

        FactoryGirl.create(:loan_realisation, :pre,
          realised_amount: Money.new(1_000_00),
          realised_loan: loan
        )
        FactoryGirl.create(:loan_realisation, :pre,
          realised_amount: Money.new(2_000_00),
          realised_loan: loan
        )
      end

      it do
        expect(loan.cumulative_pre_claim_limit_realised_amount).to eq(Money.new(3_000_00))
      end
    end

    context 'without loan_realisations' do
      it do
        expect(loan.cumulative_pre_claim_limit_realised_amount).to eql Money.new(0)
      end
    end
  end

  describe '#cumulative_post_claim_limit_realised_amount' do
    context 'with loan_realisations' do
      before do
        loan.save!

        FactoryGirl.create(:loan_realisation, :post,
          realised_amount: Money.new(1_000_00),
          realised_loan: loan
        )
        FactoryGirl.create(:loan_realisation, :post,
          realised_amount: Money.new(2_000_00),
          realised_loan: loan
        )
      end

      it do
        expect(loan.cumulative_post_claim_limit_realised_amount).to eq(Money.new(3_000_00))
      end
    end

    context 'without loan_realisations' do
      it do
        expect(loan.cumulative_post_claim_limit_realised_amount).to eql Money.new(0)
      end
    end
  end

  describe '#cumulative_realised_amount' do
    before do
      loan.save!
    end

    it 'sums all loan realisations' do
      FactoryGirl.create(:loan_realisation, realised_loan: loan, realised_amount: Money.new(123_45))
      FactoryGirl.create(:loan_realisation, realised_loan: loan, realised_amount: Money.new(678_90))

      expect(loan.cumulative_realised_amount).to eq(Money.new(123_45) + Money.new(678_90))
    end
  end

  describe "#cumulative_unrealised_recoveries_amount" do
    let(:loan) { FactoryGirl.create(:loan, :settled, :recovered) }

    it 'sums all loan realisations' do
      FactoryGirl.create(:recovery, loan: loan, amount_due_to_dti: Money.new(500_00))
      FactoryGirl.create(:loan_realisation, realised_loan: loan, realised_amount: Money.new(200_00))

      expect(loan.cumulative_unrealised_recoveries_amount).to eq(Money.new(300_00))
    end
  end

  describe "#last_realisation_amount" do
    before do
      loan.save!
    end

    it 'sums all loan realisations' do
      FactoryGirl.create(:loan_realisation, realised_loan: loan, realised_amount: Money.new(123_45))
      FactoryGirl.create(:loan_realisation, realised_loan: loan, realised_amount: Money.new(678_90))

      expect(loan.last_realisation_amount).to eq(Money.new(678_90))
    end

    it "returns 0 money when loan has no realisations" do
      expect(loan.last_realisation_amount).to eq(Money.new(0))
    end
  end

  describe '#amount_not_yet_drawn' do
    before do
      loan.save!
    end

    it 'returns loan amount minus cumulative amount drawn' do
      FactoryGirl.create(:initial_draw_change, loan: loan, amount_drawn: Money.new(123_45))
      FactoryGirl.create(:loan_change, loan: loan, amount_drawn: Money.new(678_90), change_type: ChangeType::RecordAgreedDraw)

      expect(loan.amount_not_yet_drawn).to eq(loan.amount - Money.new(802_35))
    end
  end

  describe '#efg_loan?' do
    it "returns true when loan source is SFLG and loan type is EFG" do
      loan.loan_source = Loan::SFLG_SOURCE
      loan.loan_scheme = Loan::EFG_SCHEME

      expect(loan).to be_efg_loan
    end

    it "returns false when loan source is not SFLG" do
      loan.loan_source = Loan::LEGACY_SFLG_SOURCE
      loan.loan_scheme = Loan::EFG_SCHEME

      expect(loan).not_to be_efg_loan
    end

    it "returns false when loan source is SFLG but loan type is not EFG" do
      loan.loan_source = Loan::SFLG_SOURCE
      loan.loan_scheme = Loan::SFLG_SCHEME

      expect(loan).not_to be_efg_loan
    end
  end

  describe '#legacy_loan?' do
    it "returns true when loan source is legacy SFLG" do
      loan.loan_source = Loan::LEGACY_SFLG_SOURCE

      expect(loan).to be_legacy_loan
    end

    it "returns false when loan source is not legacy SFLG" do
      loan.loan_source = Loan::SFLG_SOURCE

      expect(loan).not_to be_legacy_loan
    end
  end

  describe "#transferred_from" do
    let(:original_loan) { FactoryGirl.create(:loan, :repaid_from_transfer) }

    let(:transferred_loan) { FactoryGirl.create(:loan, transferred_from_id: original_loan.id) }

    it "returns the original loan from which this loan was transferred" do
      expect(transferred_loan.transferred_from).to eq(original_loan)
    end

    it "returns nil when loan is not a transfer" do
      expect(Loan.new.transferred_from).to be_nil
    end
  end

  describe "#loan_security_types" do
    let(:security_type1) { LoanSecurityType.find(1) }

    let(:security_type2) { LoanSecurityType.find(5) }

    let!(:loan) { FactoryGirl.create(:loan) }

    it "should return all loan security types for a loan" do
      loan.loan_security_types = [ security_type1.id, security_type2.id ]
      expect(loan.loan_security_types).to eq([ security_type1, security_type2 ])
    end

    it "should ignore blank values when setting loan security types" do
      loan.loan_security_types = [ nil ]
      expect(loan.loan_security_types).to be_empty
    end

    it "should remove existing loan securities" do
      loan.loan_security_types = [ security_type1.id ]
      expect(loan.loan_security_types).to eq([ security_type1 ])
      loan.loan_security_types = [ security_type2.id ]
      expect(loan.loan_security_types).to eq([ security_type2 ])
    end
  end

  describe "#guarantee_rate" do
    it "returns the loan's guarantee rate when present" do
      loan.guarantee_rate = 85
      expect(loan.guarantee_rate).to eq(85)
    end

    it "falls back to the loan's phase guarantee rate" do
      loan.guarantee_rate = nil
      expect(loan.guarantee_rate).to eq(75)
    end

    context 'phase 6' do
      let(:lending_limit) { FactoryGirl.build(:lending_limit, :phase_6) }

      let(:loan) { FactoryGirl.build(:loan, guarantee_rate: nil, lending_limit: lending_limit) }

      it "returns the loan's category specific guarantee rate" do
        expect(loan.guarantee_rate).to eq(75)
      end
    end  
  end

  describe "#premium_rate" do
    it "returns the loan's premium rate when present" do
      loan.premium_rate = 1.5
      expect(loan.premium_rate).to eq(1.5)
    end

    it "falls back to the loan's phase premium rate" do
      loan.premium_rate = nil
      expect(loan.premium_rate).to eq(2)
    end

    context 'phase 6' do
      let(:lending_limit) { FactoryGirl.build(:lending_limit, :phase_6) }

      let(:loan) { FactoryGirl.build(:loan, premium_rate: nil, lending_limit: lending_limit, loan_category_id: LoanCategory::TypeF.id) }

      it "returns the loan's category specific premium rate" do
        expect(loan.premium_rate).to eq(1.3)
      end
    end
  end

  describe "#state_history" do
    it "should return array of unique states a loan has or previously had" do
      loan.state = Loan::Demanded
      loan.save!

      FactoryGirl.create(:loan_state_change, loan: loan, state: Loan::Eligible)
      FactoryGirl.create(:loan_state_change, loan: loan, state: Loan::Completed)
      FactoryGirl.create(:loan_state_change, loan: loan, state: Loan::Offered)
      FactoryGirl.create(:loan_state_change, loan: loan, state: Loan::Guaranteed)
      FactoryGirl.create(:loan_state_change, loan: loan, state: Loan::Guaranteed)

      expect(loan.state_history).to eq([
        Loan::Eligible,
        Loan::Completed,
        Loan::Offered,
        Loan::Guaranteed,
        Loan::Demanded
      ])
    end
  end

  describe "#update_status!" do
    let!(:system_user) { FactoryGirl.create(:system_user) }

    before(:each) do
      loan.save!
    end

    def dispatch
      loan.update_state!(Loan::AutoRemoved, LoanEvent::NotDrawn, system_user)
    end

    it "should change the state of the loan" do
      expect {
        dispatch
      }.to change(loan, :state).to(Loan::AutoRemoved)
    end

    it "should create loan state change record" do
      expect {
        dispatch
      }.to change(LoanStateChange, :count).by(1)

      state_change = loan.state_changes.last
      expect(state_change.state).to eq(Loan::AutoRemoved)
      expect(state_change.modified_by).to eq(system_user)
      expect(state_change.event).to eq(LoanEvent::NotDrawn)
    end
  end

  describe "#corrected?" do
    before(:each) do
      loan.save!
    end

    it "should be true when loan has had a data correction" do
      FactoryGirl.create(:data_correction, loan: loan)
      expect(loan).to be_corrected
    end

    it "should be false when loan not had a data correction" do
      expect(loan).not_to be_corrected
    end
  end

  describe "#calculate_dti_amount_claimed" do
    before { loan.calculate_dti_amount_claimed }

    context 'for EFG loan' do
      let(:loan) {
        FactoryGirl.build(
          :loan,
          :sflg,
          dti_demand_outstanding: Money.new(1_000_00),
          guarantee_rate: 75
        )
      }

      it "calculates dti_amount_claimed based on demand outstanding" do
        expect(loan.dti_amount_claimed).to eq(Money.new(750_00))
      end
    end

    context 'for SFLG loan' do
      let(:loan) {
        FactoryGirl.build(
          :loan,
          :sflg,
          dti_demand_outstanding: Money.new(1_000_00),
          dti_interest: Money.new(500_00),
          dti_break_costs: Money.new(200_00),
          guarantee_rate: 75
        )
      }

      it "calculates dti_amount_claimed based on demand outstanding, interest and break costs" do
        expect(loan.dti_amount_claimed).to eq(Money.new(1_275_00))
      end
    end

    context 'for legacy SFLG loan' do
      let(:loan) {
        FactoryGirl.build(
          :loan,
          :legacy_sflg,
          dti_demand_outstanding: Money.new(1_000_00),
          dti_interest: Money.new(500_00),
          dti_break_costs: Money.new(200_00),
          guarantee_rate: 75
        )
      }

      it "calculates dti_amount_claimed based on demand outstanding, interest and break costs" do
        expect(loan.dti_amount_claimed).to eq(Money.new(1_275_00))
      end
    end

    context 'loan without demand outstanding, interest or break cost values' do
      let(:loan) { FactoryGirl.build(:loan, guarantee_rate: 75) }

      it "returns 0 when relevant values are not set on loan" do
        expect(loan.dti_amount_claimed).to eq(Money.new(0))
      end
    end
  end

  describe '#rules' do
    subject { loan.rules }

    context 'SFLG' do
      let(:loan) { FactoryGirl.build(:loan, :sflg) }

      it do
        should == Phase5Rules
      end
    end

    context 'EFG' do
      let(:lender) { FactoryGirl.build(:lender) }
      let(:lending_limit) { FactoryGirl.build(:lending_limit, lender: lender, phase_id: phase_id) }
      let(:loan) { FactoryGirl.build(:loan, :efg, lender: lender, lending_limit: lending_limit) }

      context 'phase < 6' do
        let(:phase_id) { 5 }

        it do
          should == Phase5Rules
        end
      end

      context 'phase 6' do
        let(:phase_id) { 6 }

        it do
          should == Phase6Rules
        end
      end
    end
  end
end
