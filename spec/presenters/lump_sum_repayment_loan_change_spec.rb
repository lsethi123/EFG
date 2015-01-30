require 'spec_helper'

describe LumpSumRepaymentLoanChange do
  it_behaves_like 'LoanChangePresenter'

  describe 'validations' do
    context '#lump_sum_repayment' do
      let(:loan) { FactoryGirl.create(:loan, :guaranteed, amount: Money.new(10_000_00)) }
      let(:presenter) { FactoryGirl.build(:lump_sum_repayment_loan_change, loan: loan) }

      it 'is required' do
        presenter.lump_sum_repayment = nil
        expect(presenter).not_to be_valid
      end

      it 'must be greater than zero' do
        presenter.lump_sum_repayment = '0'
        expect(presenter).not_to be_valid
      end

      it 'must not be greater than the cumulative_drawn_amount (including previous repayments)' do
        loan.stub(:cumulative_drawn_amount).and_return(Money.new(6_000_00))
        loan.stub(:cumulative_lump_sum_amount).and_return(Money.new(1_000_00))

        presenter.lump_sum_repayment = '5,000.01'
        expect(presenter).not_to be_valid

        presenter.lump_sum_repayment = '5,000'
        expect(presenter).to be_valid
      end
    end
  end

  describe '#save' do
    let(:user) { FactoryGirl.create(:lender_user) }
    let(:loan) { FactoryGirl.create(:loan, :guaranteed, repayment_duration: 60) }
    let(:presenter) { FactoryGirl.build(:lump_sum_repayment_loan_change, created_by: user, loan: loan) }

    context 'success' do
      before do
        loan.initial_draw_change.update_column :date_of_change, Date.new(2013, 2)
      end

      it 'creates a LoanChange, a PremiumSchedule, and updates the loan' do
        presenter.lump_sum_repayment = Money.new(1_000_00)

        Timecop.freeze(2013, 3, 1) do
          expect(presenter.save).to eq(true)
        end

        loan_change = loan.loan_changes.last!
        expect(loan_change.change_type).to eq(ChangeType::LumpSumRepayment)
        expect(loan_change.lump_sum_repayment).to eq(Money.new(1_000_00))
        expect(loan_change.created_by).to eq(user)

        loan.reload
        expect(loan.modified_by).to eq(user)
        expect(loan.cumulative_lump_sum_amount).to eq(Money.new(1_000_00))

        premium_schedule = loan.premium_schedules.last!
        expect(premium_schedule.premium_cheque_month).to eq('05/2013')
        expect(premium_schedule.repayment_duration).to eq(57)
      end
    end

    context 'failure' do
      it 'does not update loan' do
        presenter.lump_sum_repayment = nil
        expect(presenter.save).to eq(false)

        loan.reload
        expect(loan.modified_by).not_to eq(user)
      end
    end
  end
end
