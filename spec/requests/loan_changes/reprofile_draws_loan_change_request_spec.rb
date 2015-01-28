require 'spec_helper'

describe 'Reprofile draws loan change' do
  include LoanChangeSpecHelper

  before do
    loan.initial_draw_change.update_column(:date_of_change, Date.new(2009, 12, 25))

    visit loan_path(loan)
  end

  context 'when the loan has drawn its full amount' do
    before do
      loan.initial_draw_change.update_column(:amount_drawn, loan.amount.cents)
    end

    it do
      click_link 'Change Amount or Terms'

      expect(page).to_not have_content('Reprofile Draws')
    end
  end

  context 'when the loan has not drawn its full amount' do
    it do
      click_link 'Change Amount or Terms'
      click_link 'Reprofile Draws'

      fill_in :date_of_change, '11/9/10'
      fill_in :initial_capital_repayment_holiday, '3'
      fill_in :initial_draw_amount, '65,432.10'
      fill_in :second_draw_amount, '5,000.00'
      fill_in :second_draw_months, '6'
      fill_in :third_draw_amount, '5,000.00'
      fill_in :third_draw_months, '12'
      fill_in :fourth_draw_amount, '5,000.00'
      fill_in :fourth_draw_months, '18'

      Timecop.freeze(2010, 9, 1) do
        click_button 'Submit'
      end

      loan.reload

      loan_change = loan.loan_changes.last!
      loan_change.change_type.should == ChangeType::ReprofileDraws
      loan_change.date_of_change.should == Date.new(2010, 9, 11)

      premium_schedule = loan.premium_schedules.last!
      premium_schedule.initial_draw_amount.should == Money.new(65_432_10)
      premium_schedule.premium_cheque_month.should == '12/2010'
      premium_schedule.repayment_duration.should == 48
      premium_schedule.initial_capital_repayment_holiday.should == 3
      premium_schedule.second_draw_amount.should == Money.new(5_000_00)
      premium_schedule.second_draw_months.should == 6
      premium_schedule.third_draw_amount.should == Money.new(5_000_00)
      premium_schedule.third_draw_months.should == 12
      premium_schedule.fourth_draw_amount.should == Money.new(5_000_00)
      premium_schedule.fourth_draw_months.should == 18

      loan.modified_by.should == current_user
      loan.repayment_duration.total_months.should == 60
      loan.maturity_date.should == Date.new(2014, 12, 25)
    end
  end
end
