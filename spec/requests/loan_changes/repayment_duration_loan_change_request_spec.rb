require 'spec_helper'

describe 'Repayment duration loan change' do
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

  context 'phase 5' do
    it do
      dispatch

      loan.reload

      loan_change = loan.loan_changes.last!
      loan_change.change_type.should == ChangeType::ExtendTerm
      loan_change.date_of_change.should == Date.new(2010, 9, 11)
      loan_change.old_repayment_duration.should == 60
      loan_change.repayment_duration.should == 63

      premium_schedule = loan.premium_schedules.last!
      premium_schedule.initial_draw_amount.should == Money.new(65_432_10)
      premium_schedule.premium_cheque_month.should == '12/2010'
      premium_schedule.repayment_duration.should == 51

      loan.modified_by.should == current_user
      loan.repayment_duration.total_months.should == 63
      loan.maturity_date.should == Date.new(2015, 3, 25)
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

        page.should have_content(I18n.t('validators.phase6_amount.amount.invalid'))
      end
    end

    context 'when new loan repayment duration is invalid' do
      before do
        loan.update_attribute(:loan_category_id, LoanCategory::TypeE.id)
      end

      it 'displays error message explaining why loan term cannot be extended' do
        dispatch

        page.should have_content(I18n.t('validators.repayment_duration.repayment_duration.invalid'))
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
