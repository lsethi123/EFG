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
      page.find('#premium_schedule_initial_draw_amount').value.should == '123456.00'
      page.find('#premium_schedule_repayment_duration').value.should == '3'
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

      current_path.should == new_loan_entry_path(loan)

      premium_schedule = PremiumSchedule.last
      premium_schedule.loan.should == loan
      premium_schedule.initial_draw_year.should == 2012
      premium_schedule.initial_draw_amount.should == Money.new(123_456_00)
      premium_schedule.repayment_duration.should == 3
      premium_schedule.initial_capital_repayment_holiday.should == 0
      premium_schedule.second_draw_amount.should == 0
      premium_schedule.second_draw_months.should == 0
      premium_schedule.third_draw_amount.should be_nil
      premium_schedule.third_draw_months.should be_nil
      premium_schedule.fourth_draw_amount.should be_nil
      premium_schedule.fourth_draw_months.should be_nil
    end

    it 'does not create a new record with invalid data' do
      visit edit_loan_premium_schedule_path(loan)

      expect {
        click_button 'Submit'
      }.to change(PremiumSchedule, :count).by(0)

      current_path.should == loan_premium_schedule_path(loan)
    end

    context 'when the sum of the draw amounts exceeds the loan amount' do
      it 'fails validation and displays the correct error message' do
        fill_in :initial_draw_year, '2012'
        fill_in :initial_capital_repayment_holiday, '0'
        fill_in :initial_draw_amount, '£100,000'
        fill_in :second_draw_amount, '£100,000'
        fill_in :second_draw_months, '3'
        fill_in :third_draw_amount, '£100,000'
        fill_in :third_draw_months, '6'

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

        current_path.should == loan_premium_schedule_path(loan)
        page.should have_content(I18n.t(translation_key, loan_amount: loan.amount.format))
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

      current_path.should == new_loan_entry_path(loan)

      premium_schedule.reload
      premium_schedule.initial_draw_amount.should == Money.new(80_000_00)
      premium_schedule.second_draw_amount.should == Money.new(20_000_00)
    end

    it 'does not update the record with invalid data' do
      fill_in :initial_draw_amount, ''
      click_button 'Submit'

      current_path.should == loan_premium_schedule_path(loan)

      premium_schedule.reload.initial_draw_amount.should_not be_nil
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
