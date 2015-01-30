require 'spec_helper'

describe LoanChangePresenter, 'next premium collection values' do
  let(:loan) { FactoryGirl.create(:loan, :guaranteed, repayment_duration: 60) }
  let(:presenter) { FactoryGirl.build(:loan_change_presenter, loan: loan, date_of_change: Date.current) }
  let(:premium_schedule) { presenter.premium_schedule }

  before do
    loan.initial_draw_change.update_column(:date_of_change, Date.new(2010, 1, 15))
  end

  it 'calculates correctly when within the first month' do
    Timecop.freeze(2010, 1, 1) do
      presenter.valid?

      expect(premium_schedule.premium_cheque_month).to eq('04/2010')
      premium_schedule.repayment_duration == 57
    end
  end

  it 'calculates correctly in the month of a collection' do
    Timecop.freeze(2013, 1, 15) do
      presenter.valid?

      expect(premium_schedule.premium_cheque_month).to eq('04/2013')
      expect(premium_schedule.repayment_duration).to eq(21)
    end
  end

  it 'calculates correctly a month after a collection' do
    Timecop.freeze(2013, 2, 15) do
      presenter.valid?

      expect(premium_schedule.premium_cheque_month).to eq('04/2013')
      expect(premium_schedule.repayment_duration).to eq(21)
    end
  end

  it 'calculates correctly a day before a collection month' do
    Timecop.freeze(2013, 3, 31) do
      presenter.valid?

      expect(premium_schedule.premium_cheque_month).to eq('04/2013')
      expect(premium_schedule.repayment_duration).to eq(21)
    end
  end
end
