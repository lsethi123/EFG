require 'spec_helper'

describe 'Capital repayment loan change' do
  include LoanChangeSpecHelper

  it_behaves_like "loan change" do
    before do
      # loan must be fully drawn to access 'Capital repayment holiday' form
      loan.initial_draw_change.update_column(:amount_drawn, loan.amount.cents)
    end
  end

  context 'when the loan has NOT drawn its full amount' do
    before do
      loan.initial_draw_change.update_column(:amount_drawn, Money.new(50_000_00).cents)
    end

    it do
      visit loan_path(loan)
      click_link 'Change Amount or Terms'
      expect(page).to_not have_content('Capital Repayment Holiday')
    end
  end

  context 'when the loan has drawn its full amount' do
    before do
      loan.initial_draw_change.update_column(:amount_drawn, loan.amount.cents)
      loan.initial_draw_change.update_column(:date_of_change, Date.new(2009, 12, 25))
    end

    it do
      dispatch

      loan.reload

      loan_change = loan.loan_changes.last!
      loan_change.change_type.should == ChangeType::CapitalRepaymentHoliday
      loan_change.date_of_change.should == Date.new(2010, 9, 11)

      premium_schedule = loan.premium_schedules.last!
      premium_schedule.initial_draw_amount.should == Money.new(65_432_10)
      premium_schedule.premium_cheque_month.should == '12/2010'
      premium_schedule.repayment_duration.should == 48
      premium_schedule.initial_capital_repayment_holiday.should == 3

      loan.modified_by.should == current_user
      loan.repayment_duration.total_months.should == 60
      loan.maturity_date.should == Date.new(2014, 12, 25)
    end
  end

  private

  def dispatch
    visit loan_path(loan)

    click_link 'Change Amount or Terms'
    click_link 'Capital Repayment Holiday'

    fill_in :date_of_change, '11/9/10'
    fill_in :initial_draw_amount, '65,432.10'
    fill_in :initial_capital_repayment_holiday, '3'

    Timecop.freeze(2010, 9, 1) do
      click_button 'Submit'
    end
  end
end
