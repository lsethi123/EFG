require 'spec_helper'

describe CapitalRepaymentHolidayLoanChange do
  it_behaves_like 'LoanChangePresenter'

  describe 'validations' do
    context '#initial_capital_repayment_holiday' do
      let(:loan) { FactoryGirl.create(:loan, :guaranteed) }
      let(:presenter) { FactoryGirl.build(:capital_repayment_holiday_loan_change, loan: loan) }

      it 'is required' do
        presenter.initial_capital_repayment_holiday = nil
        presenter.should_not be_valid
      end

      it 'must be greater than zero' do
        presenter.initial_capital_repayment_holiday = '0'
        presenter.should_not be_valid
      end
    end
  end

  describe '#save' do
    let(:loan) { FactoryGirl.create(:loan, :guaranteed, repayment_duration: 60, repayment_frequency_id: 4) }
    let(:presenter) { FactoryGirl.build(:capital_repayment_holiday_loan_change, created_by: user, loan: loan) }
    let(:user) { FactoryGirl.create(:lender_user) }

    context 'success' do
      before do
        loan.initial_draw_change.update_column :date_of_change, Date.new(2013, 2)
      end

      it 'creates a LoanChange, a PremiumSchedule, and updates the loan' do
        presenter.initial_capital_repayment_holiday = 6

        Timecop.freeze(2013, 3, 1) do
          presenter.save.should == true
        end

        loan_change = loan.loan_changes.last!
        loan_change.change_type.should == ChangeType::CapitalRepaymentHoliday
        loan_change.created_by.should == user

        loan.reload
        loan.modified_by.should == user

        premium_schedule = loan.premium_schedules.last!
        premium_schedule.premium_cheque_month.should == '05/2013'
        premium_schedule.repayment_duration.should == 57
      end
    end

    context 'failure' do
      it 'does not update loan' do
        presenter.initial_capital_repayment_holiday = nil
        presenter.save.should == false

        loan.reload
        loan.modified_by.should_not == user
      end
    end
  end
end
