require 'spec_helper'

describe 'Repayment duration loan change' do
  include LoanChangeSpecHelper

  it_behaves_like "loan change on loan with tranche drawdowns"
  it_behaves_like "loan change on loan with capital repayment holiday"
  it_behaves_like "loan change on loan with no premium schedule"

  before do
    loan.initial_draw_change.update_column(:date_of_change, Date.new(2009, 12, 25))
  end

  context 'phase 5' do
    it do
      dispatch

      loan.reload

      loan_change = loan.loan_changes.last!
      expect(loan_change.change_type).to eq(ChangeType::ExtendTerm)
      expect(loan_change.date_of_change).to eq(Date.new(2010, 9, 11))
      expect(loan_change.old_repayment_duration).to eq(60)
      expect(loan_change.repayment_duration).to eq(63)

      premium_schedule = loan.premium_schedules.last!
      expect(premium_schedule.initial_draw_amount).to eq(Money.new(65_432_10))
      expect(premium_schedule.premium_cheque_month).to eq('12/2010')
      expect(premium_schedule.repayment_duration).to eq(51)

      expect(loan.modified_by).to eq(current_user)
      expect(loan.repayment_duration.total_months).to eq(63)
      expect(loan.maturity_date).to eq(Date.new(2015, 3, 25))
    end
  end

  context 'phase 6' do
    before do
      loan.lending_limit.update_attribute(:phase_id, 6)
    end

    context 'when loan amount is invalid' do
      before do
        loan.update_attribute(:amount, Money.new(750_000_00))
      end

      it 'displays error message explaining why loan amount is invalid' do
        dispatch

        expect(page).to have_content(I18n.t('validators.phase6_amount.amount.invalid'))
      end
    end

    context 'when new loan repayment duration is invalid' do
      before do
        loan.update_attribute(:loan_category_id, LoanCategory::TypeE.id)
      end

      it 'displays error message explaining why loan term cannot be extended' do
        dispatch

        expect(page).to have_content(I18n.t('validators.repayment_duration.repayment_duration.invalid'))
      end
    end
  end

  private

  def dispatch
    visit loan_path(loan)

    click_link 'Change Amount or Terms'
    click_link 'Extend or Reduce Loan Term'

    fill_in :date_of_change, '11/9/10'
    fill_in :added_months, '3'
    fill_in :initial_draw_amount, '65,432.10'

    Timecop.freeze(2010, 9, 1) do
      click_button 'Submit'
    end
  end

end
