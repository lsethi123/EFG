require 'spec_helper'

describe 'Reprofile draws loan change' do
  include LoanChangeSpecHelper

  it_behaves_like "loan change on loan with capital repayment holiday"
  it_behaves_like "loan change on loan with no premium schedule"

  before do
    loan.initial_draw_change.update_column(:date_of_change, Date.new(2009, 12, 25))
  end

  context 'when the loan has drawn its full amount' do
    before do
      loan.initial_draw_change.update_column(:amount_drawn, loan.amount.cents)
    end

    it do
      visit loan_path(loan)
      click_link 'Change Amount or Terms'
      expect(page).to_not have_css('a', text: 'Reprofile Draws')
    end
  end

  context 'when the loan has not drawn its full amount' do
    it do
      dispatch

      loan.reload

      loan_change = loan.loan_changes.last!
      expect(loan_change.change_type).to eq(ChangeType::ReprofileDraws)
      expect(loan_change.date_of_change).to eq(Date.new(2010, 9, 11))

      premium_schedule = loan.premium_schedules.last!
      expect(premium_schedule.initial_draw_amount).to eq(Money.new(65_432_10))
      expect(premium_schedule.premium_cheque_month).to eq('12/2010')
      expect(premium_schedule.repayment_duration).to eq(48)
      expect(premium_schedule.second_draw_amount).to eq(Money.new(5_000_00))
      expect(premium_schedule.second_draw_months).to eq(6)
      expect(premium_schedule.third_draw_amount).to eq(Money.new(5_000_00))
      expect(premium_schedule.third_draw_months).to eq(12)
      expect(premium_schedule.fourth_draw_amount).to eq(Money.new(5_000_00))
      expect(premium_schedule.fourth_draw_months).to eq(18)

      expect(loan.modified_by).to eq(current_user)
      expect(loan.repayment_duration.total_months).to eq(60)
      expect(loan.maturity_date).to eq(Date.new(2014, 12, 25))
    end
  end

  context 'when a tranche drawdown is set but initial draw amount is not' do
    it 'renders validation error' do
      visit loan_path(loan)

      click_link 'Change Amount or Terms'
      click_link 'Reprofile Draws'

      fill_in :date_of_change, '11/9/10'
      fill_in :second_draw_amount, '5,000.00'
      fill_in :second_draw_months, '6'

      Timecop.freeze(2010, 9, 1) do
        click_button 'Submit'
      end

      within '.loan_change_initial_draw_amount' do
        expect(page).to have_content("must not be blank")
      end
    end
  end

  private

  def dispatch
    visit loan_path(loan)

    click_link 'Change Amount or Terms'
    click_link 'Reprofile Draws'

    fill_in :date_of_change, '11/9/10'
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
  end
end
