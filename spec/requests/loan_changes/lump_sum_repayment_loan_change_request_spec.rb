require 'spec_helper'

describe 'Lump sum repayment loan change' do
  include LoanChangeSpecHelper

  let(:loan) {
    FactoryGirl.create(:loan, :guaranteed, :with_premium_schedule, {
        amount: Money.new(100_000_00),
        maturity_date: Date.new(2014, 12, 25),
        repayment_duration: 60,
        repayment_frequency_id: RepaymentFrequency::Quarterly.id
      }
    )
  }

  it_behaves_like "loan change"

  before do
    loan.initial_draw_change.update_column(:date_of_change, Date.new(2009, 12, 25))
  end

  it do
    dispatch

    loan.reload

    loan_change = loan.loan_changes.last!
    loan_change.change_type.should == ChangeType::LumpSumRepayment
    loan_change.date_of_change.should == Date.new(2011, 12, 1)
    loan_change.lump_sum_repayment.should == Money.new(1_234_56)

    premium_schedule = loan.premium_schedules.last!
    premium_schedule.initial_draw_amount.should == Money.new(65_432_10)
    premium_schedule.premium_cheque_month.should == '03/2012'
    premium_schedule.repayment_duration.should == 33

    loan.maturity_date.should == Date.new(2014, 12, 25)
    loan.modified_by.should == current_user
  end

  private

  def dispatch
    visit loan_path(loan)
    click_link 'Change Amount or Terms'
    click_link 'Lump Sum Repayment'

    fill_in :date_of_change, '1/12/11'
    fill_in :lump_sum_repayment, '1234.56'
    fill_in :initial_draw_amount, '65,432.10'

    Timecop.freeze(2011, 12, 1) do
      click_button 'Submit'
    end
  end
end
