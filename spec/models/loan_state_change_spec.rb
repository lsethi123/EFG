require 'spec_helper'

describe LoanStateChange do
  let(:loan_state_change) { FactoryGirl.build(:loan_state_change) }

  describe 'validations' do
    it 'has a valid Factory' do
      expect(loan_state_change).to be_valid
    end

    it 'strictly requires a loan' do
      expect {
        loan_state_change.loan = nil
        loan_state_change.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'strictly requires a state' do
      expect {
        loan_state_change.state = nil
        loan_state_change.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'strictly requires an event_id' do
      expect {
        loan_state_change.event_id = nil
        loan_state_change.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'strictly requires a known event_id' do
      expect {
        loan_state_change.event_id = 99
        loan_state_change.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'strictly requires modified_at' do
      expect {
        loan_state_change.modified_at = nil
        loan_state_change.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'strictly requires a modified_by_id' do
      expect {
        loan_state_change.modified_by_id = nil
        loan_state_change.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end
  end

  describe ".log" do
    let(:loan) { FactoryGirl.create(:loan, :guaranteed) }
    let(:time) { Time.now }

    before do
      Timecop.freeze(time) do
        LoanStateChange.log(loan, LoanEvent::Guaranteed, loan.modified_by)
      end
    end

    it "should create loan state change for the specified loan and event" do
      loan_state_change = LoanStateChange.last
      expect(loan_state_change.loan).to eq(loan)
      expect(loan_state_change.state).to eq(loan.state)
      expect(loan_state_change.event_id).to eq(LoanEvent::Guaranteed.id)
      expect(loan_state_change.modified_by).to eq(loan.modified_by)
      expect(loan_state_change.modified_at.to_i).to eq(time.to_i)
    end

    it 'updates last_modified_at on the loan' do
      loan.reload
      expect(loan.last_modified_at.to_i).to eq(time.to_i)
    end
  end
end
