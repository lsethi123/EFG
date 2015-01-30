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
    expect(loan_change.change_type).to eq(ChangeType::RepaymentFrequency)
    expect(loan_change.date_of_change).to eq(Date.new(2010, 9, 11))
    expect(loan_change.repayment_frequency_id).to eq(RepaymentFrequency::Monthly.id)
    expect(loan_change.old_repayment_frequency_id).to eq(RepaymentFrequency::Quarterly.id)

    premium_schedule = loan.premium_schedules.last!
    expect(premium_schedule.initial_draw_amount).to eq(Money.new(65_432_10))
    expect(premium_schedule.premium_cheque_month).to eq('12/2010')
    expect(premium_schedule.repayment_duration).to eq(48)

    expect(loan.modified_by).to eq(current_user)
    expect(loan.repayment_frequency_id).to eq(RepaymentFrequency::Monthly.id)

    click_link 'Loan Changes'
    click_link 'Repayment frequency'

    expect(page).to have_content('Monthly')
    expect(page).to have_content('Quarterly')
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
