require 'spec_helper'

describe CapitalRepaymentHolidayLoanChange do
  it_behaves_like 'LoanChangePresenter' do
    let(:presenter_factory_options) { { loan: FactoryGirl.create(:loan, :guaranteed, :with_premium_schedule, :fully_drawn) } }
  end

  describe '#initialize' do
    let(:loan) { FactoryGirl.create(:loan, :guaranteed, amount: Money.new(20_000_00)) }
    let(:presenter) { FactoryGirl.build(:capital_repayment_holiday_loan_change, loan: loan) }

    context 'when the full amount has not been fully drawn' do
      before do
        loan.initial_draw_change.update_column(:amount_drawn, Money.new(5_000_00).cents)
      end

      it 'is not allowed' do
        expect {
          presenter
        }.to raise_error(CapitalRepaymentHolidayLoanChange::LoanNotFullyDrawnError)
      end
    end
  end

  describe 'validations' do
    context '#initial_capital_repayment_holiday' do
      let(:loan) { FactoryGirl.create(:loan, :guaranteed, :with_premium_schedule, :fully_drawn) }
      let(:presenter) { FactoryGirl.build(:capital_repayment_holiday_loan_change, loan: loan) }

      it 'is required' do
        presenter.initial_capital_repayment_holiday = nil
        expect(presenter).not_to be_valid
      end

      it 'must be greater than zero' do
        presenter.initial_capital_repayment_holiday = '0'
        expect(presenter).not_to be_valid
      end
    end
  end

  describe '#save' do
    let(:loan) { FactoryGirl.create(:loan, :guaranteed, :with_premium_schedule, :fully_drawn, repayment_duration: 60, repayment_frequency_id: 4) }
    let(:presenter) { FactoryGirl.build(:capital_repayment_holiday_loan_change, created_by: user, loan: loan) }
    let(:user) { FactoryGirl.create(:lender_user) }

    context 'success' do
      before do
        loan.initial_draw_change.update_column :date_of_change, Date.new(2013, 2)
      end

      it 'creates a LoanChange, a PremiumSchedule, and updates the loan' do
        presenter.initial_capital_repayment_holiday = 6

        Timecop.freeze(2013, 3, 1) do
          expect(presenter.save).to eq(true)
        end

        loan_change = loan.loan_changes.last!
        expect(loan_change.change_type).to eq(ChangeType::CapitalRepaymentHoliday)
        expect(loan_change.created_by).to eq(user)

        loan.reload
        expect(loan.modified_by).to eq(user)

        premium_schedule = loan.premium_schedules.last!
        expect(premium_schedule.premium_cheque_month).to eq('05/2013')
        expect(premium_schedule.repayment_duration).to eq(57)
      end
    end

    context 'failure' do
      it 'does not update loan' do
        presenter.initial_capital_repayment_holiday = nil
        expect(presenter.save).to eq(false)

        loan.reload
        expect(loan.modified_by).not_to eq(user)
      end
    end
  end
end
