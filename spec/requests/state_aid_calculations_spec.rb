# encoding: utf-8

require 'spec_helper'

describe 'state aid calculations' do
  let(:current_lender) { FactoryGirl.create(:lender) }
  let(:current_user) { FactoryGirl.create(:lender_user, lender: current_lender) }

  describe 'creating' do
    let!(:loan) { FactoryGirl.create(:loan, :eligible, lender: current_lender, amount: '123456', repayment_duration: { months: 3 }) }

    before do
      login_as(current_user, scope: :user)
      navigate_to_premium_schedule_page
    end

    it 'pre-fills some fields' do
      expect(page.find('#premium_schedule_initial_draw_amount').value).to eq('123456.00')
      expect(page.find('#premium_schedule_repayment_duration').value).to eq('3')
    end

    it 'creates a new record with valid data' do
      fill_in :initial_draw_year, '2012'
      fill_in :initial_draw_amount, '£123,456'
      fill_in :initial_capital_repayment_holiday, '0'
      fill_in :second_draw_amount, '£0'
      fill_in :second_draw_months, '0'

      expect {
        click_button 'Submit'
      }.to change(PremiumSchedule, :count).by(1)

      expect(current_path).to eq(new_loan_entry_path(loan))

      premium_schedule = PremiumSchedule.last
      expect(premium_schedule.loan).to eq(loan)
      expect(premium_schedule.initial_draw_year).to eq(2012)
      expect(premium_schedule.initial_draw_amount).to eq(Money.new(123_456_00))
      expect(premium_schedule.repayment_duration).to eq(3)
      expect(premium_schedule.initial_capital_repayment_holiday).to eq(0)
      expect(premium_schedule.second_draw_amount).to eq(0)
      expect(premium_schedule.second_draw_months).to eq(0)
      expect(premium_schedule.third_draw_amount).to be_nil
      expect(premium_schedule.third_draw_months).to be_nil
      expect(premium_schedule.fourth_draw_amount).to be_nil
      expect(premium_schedule.fourth_draw_months).to be_nil
    end

    it 'does not create a new record with invalid data' do
      visit edit_loan_premium_schedule_path(loan)

      expect {
        click_button 'Submit'
      }.to change(PremiumSchedule, :count).by(0)

      expect(current_path).to eq(loan_premium_schedule_path(loan))
    end

    context 'when the sum of the draw amounts exceeds the loan amount' do
      it 'fails validation and displays the correct error message' do
        fill_in :initial_draw_year, '2012'
        fill_in :initial_capital_repayment_holiday, '0'
        fill_in :initial_draw_amount, '£100,000'
        fill_in :second_draw_amount, '£100,000'
        fill_in :second_draw_months, 3
        fill_in :third_draw_amount, '£100,000'
        fill_in :third_draw_months, 6

        expect {
          click_button 'Submit'
        }.to change(PremiumSchedule, :count).by(0)

        translation_key = %w(
          activerecord
          errors
          models
          premium_schedule
          attributes
          initial_draw_amount
          not_less_than_or_equal_to_loan_amount
        ).join('.')

        expect(current_path).to eq(loan_premium_schedule_path(loan))
        expect(page).to have_content(I18n.t(translation_key, loan_amount: loan.amount.format))
      end
    end
  end

  describe 'updating an existing premium_schedule' do
    let!(:loan) { FactoryGirl.create(:loan, :eligible, lender: current_lender, amount: Money.new(100_000_00)) }
    let!(:premium_schedule) { FactoryGirl.create(:premium_schedule, loan: loan) }

    before do
      login_as(current_user, scope: :user)
      navigate_to_premium_schedule_page
    end

    it 'updates the record' do
      fill_in :initial_draw_amount, '£80,000'
      fill_in :second_draw_amount, '£20,000'
      fill_in :second_draw_months, '10'
      click_button 'Submit'

      expect(current_path).to eq(new_loan_entry_path(loan))

      premium_schedule.reload
      expect(premium_schedule.initial_draw_amount).to eq(Money.new(80_000_00))
      expect(premium_schedule.second_draw_amount).to eq(Money.new(20_000_00))
    end

    it 'does not update the record with invalid data' do
      fill_in :initial_draw_amount, ''
      click_button 'Submit'

      expect(current_path).to eq(loan_premium_schedule_path(loan))

      expect(premium_schedule.reload.initial_draw_amount).not_to be_nil
    end
  end

  private
    def navigate_to_premium_schedule_page
      visit loan_path(loan)
      click_link 'Loan Entry'
      click_button 'State Aid Calculation'
    end

    def fill_in(attribute, value)
      page.fill_in "premium_schedule_#{attribute}", with: value
    end
end
