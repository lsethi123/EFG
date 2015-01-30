# encoding: utf-8

require 'spec_helper'

describe 'loan change' do
  let(:current_user) { FactoryGirl.create(:lender_user, lender: loan.lender) }
  before { login_as(current_user, scope: :user) }

  let(:loan) { FactoryGirl.create(:loan, :guaranteed, amount: Money.new(100_000_00), maturity_date: Date.new(2014, 12, 25), repayment_duration: 60, repayment_frequency_id: RepaymentFrequency::Quarterly.id) }

  before do
    loan.initial_draw_change.update_column(:date_of_change, Date.new(2009, 12, 25))
  end

  context 'lump_sum_repayment' do
    before do
      visit_loan_changes
      click_link 'Lump Sum Repayment'
    end

    it 'works' do
      fill_in :date_of_change, '1/12/11'
      fill_in :lump_sum_repayment, '1234.56'
      fill_in :initial_draw_amount, '65,432.10'

      Timecop.freeze(2011, 12, 1) do
        click_button 'Submit'
      end

      loan_change = loan.loan_changes.last!
      expect(loan_change.change_type).to eq(ChangeType::LumpSumRepayment)
      expect(loan_change.date_of_change).to eq(Date.new(2011, 12, 1))
      expect(loan_change.lump_sum_repayment).to eq(Money.new(1_234_56))

      premium_schedule = loan.premium_schedules.last!
      expect(premium_schedule.initial_draw_amount).to eq(Money.new(65_432_10))
      expect(premium_schedule.premium_cheque_month).to eq('03/2012')
      expect(premium_schedule.repayment_duration).to eq(33)

      loan.reload
      expect(loan.maturity_date).to eq(Date.new(2014, 12, 25))
      expect(loan.modified_by).to eq(current_user)
    end
  end

  context 'repayment_duration' do
    def dispatch
      visit_loan_changes
      click_link 'Extend or Reduce Loan Term'
      fill_in :date_of_change, '11/9/10'
      fill_in :added_months, '3'
      fill_in :initial_draw_amount, '65,432.10'
    end

    context 'phase 5' do
      it 'works' do
        dispatch

        Timecop.freeze(2010, 9, 1) do
          click_button 'Submit'
        end

        loan_change = loan.loan_changes.last!
        expect(loan_change.change_type).to eq(ChangeType::ExtendTerm)
        expect(loan_change.date_of_change).to eq(Date.new(2010, 9, 11))
        expect(loan_change.old_repayment_duration).to eq(60)
        expect(loan_change.repayment_duration).to eq(63)

        premium_schedule = loan.premium_schedules.last!
        expect(premium_schedule.initial_draw_amount).to eq(Money.new(65_432_10))
        expect(premium_schedule.premium_cheque_month).to eq('12/2010')
        expect(premium_schedule.repayment_duration).to eq(51)

        loan.reload
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

          Timecop.freeze(2010, 9, 1) do
            click_button 'Submit'
          end

          expect(page).to have_content(I18n.t('validators.phase6_amount.amount.invalid'))
        end
      end

      context 'when new loan repayment duration is invalid' do
        before do
          loan.update_attribute(:loan_category_id, LoanCategory::TypeE.id)
        end

        it 'displays error message explaining why loan term cannot be extended' do
          dispatch

          Timecop.freeze(2010, 9, 1) do
            click_button 'Submit'
          end

          expect(page).to have_content(I18n.t('validators.repayment_duration.repayment_duration.invalid'))
        end
      end
    end
  end

  context 'repayment_frequency' do
    before do
      Timecop.freeze(2010, 9, 1)
      visit_loan_changes
      click_link 'Repayment Frequency'
    end

    after { Timecop.return }

    it 'works' do
      fill_in :date_of_change, '11/9/10'
      fill_in :initial_draw_amount, '65,432.10'

      select :repayment_frequency_id, RepaymentFrequency::Monthly.name

      click_button 'Submit'

      loan_change = loan.loan_changes.last!
      expect(loan_change.change_type).to eq(ChangeType::RepaymentFrequency)
      expect(loan_change.date_of_change).to eq(Date.new(2010, 9, 11))
      expect(loan_change.repayment_frequency_id).to eq(RepaymentFrequency::Monthly.id)
      expect(loan_change.old_repayment_frequency_id).to eq(RepaymentFrequency::Quarterly.id)

      premium_schedule = loan.premium_schedules.last!
      expect(premium_schedule.initial_draw_amount).to eq(Money.new(65_432_10))
      expect(premium_schedule.premium_cheque_month).to eq('12/2010')
      expect(premium_schedule.repayment_duration).to eq(48)

      loan.reload
      expect(loan.modified_by).to eq(current_user)
      expect(loan.repayment_frequency_id).to eq(RepaymentFrequency::Monthly.id)

      click_link 'Loan Changes'
      click_link 'Repayment frequency'

      expect(page).to have_content('Monthly')
      expect(page).to have_content('Quarterly')
    end
  end

  context 'reprofile_draws' do
    before do
      visit_loan_changes
      click_link 'Reprofile Draws'
    end

    it 'works' do
      fill_in :date_of_change, '11/9/10'
      fill_in :initial_draw_amount, '65,432.10'
      fill_in :initial_capital_repayment_holiday, '3'
      fill_in :second_draw_amount, '5,000.00'
      fill_in :second_draw_months, '6'
      fill_in :third_draw_amount, '5,000.00'
      fill_in :third_draw_months, '12'
      fill_in :fourth_draw_amount, '5,000.00'
      fill_in :fourth_draw_months, '18'

      Timecop.freeze(2010, 9, 1) do
        click_button 'Submit'
      end

      loan_change = loan.loan_changes.last!
      expect(loan_change.change_type).to eq(ChangeType::ReprofileDraws)
      expect(loan_change.date_of_change).to eq(Date.new(2010, 9, 11))

      premium_schedule = loan.premium_schedules.last!
      expect(premium_schedule.initial_draw_amount).to eq(Money.new(65_432_10))
      expect(premium_schedule.premium_cheque_month).to eq('12/2010')
      expect(premium_schedule.repayment_duration).to eq(48)
      expect(premium_schedule.initial_capital_repayment_holiday).to eq(3)
      expect(premium_schedule.second_draw_amount).to eq(Money.new(5_000_00))
      expect(premium_schedule.second_draw_months).to eq(6)
      expect(premium_schedule.third_draw_amount).to eq(Money.new(5_000_00))
      expect(premium_schedule.third_draw_months).to eq(12)
      expect(premium_schedule.fourth_draw_amount).to eq(Money.new(5_000_00))
      expect(premium_schedule.fourth_draw_months).to eq(18)

      loan.reload
      expect(loan.modified_by).to eq(current_user)
      expect(loan.repayment_duration.total_months).to eq(60)
      expect(loan.maturity_date).to eq(Date.new(2014, 12, 25))
    end
  end

  private
    def fill_in(attribute, value)
      page.fill_in "loan_change_#{attribute}", with: value
    end

    def visit_loan_changes
      visit loan_path(loan)
      click_link 'Change Amount or Terms'
    end

    def select(attribute, value)
      page.select value, from: "loan_change_#{attribute}"
    end
end
