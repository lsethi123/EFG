require 'spec_helper'

describe 'Repayment frequency loan change' do
  include LoanChangeSpecHelper

  it_behaves_like "loan change on loan with tranche drawdowns"
  it_behaves_like "loan change on loan with capital repayment holiday"
  it_behaves_like "loan change on loan with no premium schedule"

  before do
    loan.initial_draw_change.update_column(:date_of_change, Date.new(2009, 12, 25))
    Timecop.freeze(2010, 9, 1)
  end

  after { Timecop.return }

  it do
    dispatch

    loan.reload

    loan_change = loan.loan_changes.last!
    loan_change.change_type.should == ChangeType::RepaymentFrequency
    loan_change.date_of_change.should == Date.new(2010, 9, 11)
    loan_change.repayment_frequency_id.should == RepaymentFrequency::Monthly.id
    loan_change.old_repayment_frequency_id.should == RepaymentFrequency::Quarterly.id

    premium_schedule = loan.premium_schedules.last!
    premium_schedule.initial_draw_amount.should == Money.new(65_432_10)
    premium_schedule.premium_cheque_month.should == '12/2010'
    premium_schedule.repayment_duration.should == 48

    loan.modified_by.should == current_user
    loan.repayment_frequency_id.should == RepaymentFrequency::Monthly.id

    click_link 'Loan Changes'
    click_link 'Repayment frequency'

    page.should have_content('Monthly')
    page.should have_content('Quarterly')
  end

  private

  def dispatch
    visit loan_path(loan)
    click_link 'Change Amount or Terms'
    click_link 'Repayment Frequency'
    fill_in :date_of_change, '11/9/10'
    fill_in :initial_draw_amount, '65,432.10'

    select :repayment_frequency_id, RepaymentFrequency::Monthly.name

    click_button 'Submit'
  end
end
