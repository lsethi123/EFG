require 'spec_helper'

describe AgreedDraw do
  describe 'validations' do
    let(:agreed_draw) { FactoryGirl.build(:agreed_draw) }

    it 'has a valid factory' do
      expect(agreed_draw).to be_valid
    end

    it 'strictly requires a created_by' do
      expect {
        agreed_draw.created_by = nil
        agreed_draw.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'requires a date_of_change' do
      agreed_draw.date_of_change = ''
      expect(agreed_draw).not_to be_valid
    end

    context '#agreed_draw' do
      let(:loan) { FactoryGirl.create(:loan, :guaranteed) }

      it 'must be present' do
        agreed_draw.amount_drawn = ''
        expect(agreed_draw).not_to be_valid
      end

      it 'must be positive' do
        agreed_draw.amount_drawn = '-0.01'
        expect(agreed_draw).not_to be_valid
      end

      it 'must be less than the remaining undrawn amount' do
        agreed_draw.amount_drawn = '100,000'
        expect(agreed_draw).not_to be_valid
      end
    end
  end

  describe '#save' do
    let(:user) { FactoryGirl.create(:lender_user, lender: loan.lender) }
    let(:yesterday) { 1.day.ago }
    let(:loan) { FactoryGirl.create(:loan, :guaranteed, last_modified_at: yesterday) }
    let(:agreed_draw) {
      FactoryGirl.build(:agreed_draw,
        loan: loan,
        created_by: user,
        amount_drawn: Money.new(1_000_00),
        date_of_change: '1/1/11'
      )
    }

    it do
      expect {
        expect(agreed_draw.save).to eq(true)
      }.to change(LoanChange, :count).by(1)

      loan_change = loan.loan_changes.last!
      expect(loan_change.amount_drawn).to eq(Money.new(1_000_00))
      expect(loan_change.change_type).to eq(ChangeType::RecordAgreedDraw)
      expect(loan_change.created_by).to eq(user)
      expect(loan_change.date_of_change).to eq(Date.new(2011))
      expect(loan_change.modified_date).to eq(Date.current)

      loan.reload
      expect(loan.last_modified_at).to be > yesterday
      expect(loan.modified_by).to eq(user)
    end
  end
end
