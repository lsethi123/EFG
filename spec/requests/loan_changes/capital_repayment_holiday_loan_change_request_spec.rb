require 'spec_helper'

describe 'Capital repayment loan change' do
  include LoanChangeSpecHelper

  context 'when the loan has NOT drawn its full amount' do
    before do
      loan.initial_draw_change.update_column(:amount_drawn, Money.new(50_000_00).cents)
    end

    it do
      visit loan_path(loan)
      click_link 'Change Amount or Terms'
      expect(page).to_not have_css('a', text: 'Capital Repayment Holiday')
    end
  end

  context 'when the loan has drawn its full amount' do
    before do
      loan.initial_draw_change.update_column(:amount_drawn, loan.amount.cents)
      loan.initial_draw_change.update_column(:date_of_change, Date.new(2009, 12, 25))
    end

    it_behaves_like "loan change on loan with tranche drawdowns"
    it_behaves_like "loan change on loan with no premium schedule"

    it do
      dispatch

      loan.reload

      loan_change = loan.loan_changes.last!
      expect(loan_change.change_type).to eq(ChangeType::CapitalRepaymentHoliday)
      expect(loan_change.date_of_change).to eq(Date.new(2010, 9, 11))

      premium_schedule = loan.premium_schedules.last!
      expect(premium_schedule.initial_draw_amount).to eq(Money.new(65_432_10))
      expect(premium_schedule.premium_cheque_month).to eq('12/2010')
      expect(premium_schedule.repayment_duration).to eq(48)
      expect(premium_schedule.initial_capital_repayment_holiday).to eq(3)

      expect(loan.modified_by).to eq(current_user)
      expect(loan.repayment_duration.total_months).to eq(60)
      expect(loan.maturity_date).to eq(Date.new(2014, 12, 25))
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
