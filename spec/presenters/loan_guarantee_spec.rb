require 'spec_helper'

describe LoanGuarantee do
  describe "validations" do
    let(:loan_guarantee) { FactoryGirl.build(:loan_guarantee) }

    it "should have a valid factory" do
      expect(loan_guarantee).to be_valid
    end

    it "should be invalid if it hasn't received a declaration" do
      loan_guarantee.received_declaration = false
      expect(loan_guarantee).not_to be_valid
    end

    it "should be invalid if they can't settle first premium" do
      loan_guarantee.first_pp_received = false
      expect(loan_guarantee).not_to be_valid
    end

    it "should be invalid without a signed direct debit" do
      loan_guarantee.signed_direct_debit_received = false
      expect(loan_guarantee).not_to be_valid
    end

    it "should be invalid without an initial draw date" do
      loan_guarantee.initial_draw_date = ''
      expect(loan_guarantee).not_to be_valid
    end

    it "should be invalid when initial draw date is before facility letter date" do
      loan_guarantee.initial_draw_date = loan_guarantee.loan.facility_letter_date - 1.day
      expect(loan_guarantee).not_to be_valid

      loan_guarantee.initial_draw_date = loan_guarantee.loan.facility_letter_date
      expect(loan_guarantee).to be_valid
    end

    it "should be invalid when initial draw date is more than 6 months after facility letter date" do
      loan_guarantee.initial_draw_date = loan_guarantee.loan.facility_letter_date.advance(months: 6, days: 1)
      expect(loan_guarantee).not_to be_valid

      loan_guarantee.initial_draw_date = loan_guarantee.loan.facility_letter_date.advance(months: 6)
      expect(loan_guarantee).to be_valid
    end
  end

  describe '#save' do
    let(:lender_user) { FactoryGirl.create(:lender_user) }
    let(:premium_schedule) { FactoryGirl.build(:premium_schedule, initial_draw_amount: Money.new(5_000_00)) }
    let(:loan) { FactoryGirl.create(:loan, :offered, premium_schedules: [premium_schedule], amount: Money.new(5_000_00)) }
    let(:loan_guarantee) do
      LoanGuarantee.new(loan).tap do |loan_guarantee|
        loan_guarantee.attributes = FactoryGirl.attributes_for(:loan_guarantee)
        loan_guarantee.modified_by = lender_user
      end
    end

    it 'creates an InitialDrawChange' do
      expect(loan_guarantee.save).to eq(true)

      initial_draw_change = loan.initial_draw_change
      expect(initial_draw_change.amount_drawn).to eq(Money.new(5_000_00))
      expect(initial_draw_change.change_type).to eq(nil)
      expect(initial_draw_change.created_by).to eq(lender_user)
      expect(initial_draw_change.date_of_change).to eq(Date.current)
      expect(initial_draw_change.modified_date).to eq(Date.current)
      expect(initial_draw_change.seq).to eq(0)
    end

    it 'creates a LoanStateChange' do
      expect {
        expect(loan_guarantee.save).to eq(true)
      }.to change(LoanStateChange, :count).by(1)

      state_change = loan.state_changes.last
      expect(state_change.event_id).to eq(7)
      expect(state_change.state).to eq(Loan::Guaranteed)
    end

    it "updates the maturity date to the initial draw date + loan term" do
      loan.repayment_duration = {years: 3}
      loan.facility_letter_date = Date.new(2012, 10, 20)
      loan_guarantee.initial_draw_date = Date.new(2012, 11, 30)

      loan_guarantee.save

      loan.reload
      expect(loan.maturity_date).to eq(Date.new(2015, 11, 30))
    end
  end
end
