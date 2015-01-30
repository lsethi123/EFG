require 'spec_helper'

describe Phase5StateAidCalculator do
  let(:loan) {
    double(:loan,
      amount: Money.new(100_000_00),
      guarantee_rate: BigDecimal.new('75'),
      euro_conversion_rate: BigDecimal.new('1.1974'),
      premium_schedule: premium_schedule
    )
  }

  let(:premium_schedule) {
    double(:premium_schedule,
      total_premiums: Money.new(1_652_75)
    )
  }

  let(:state_aid_calculator) { Phase5StateAidCalculator.new(loan) }

  it 'calculates state aid in EUR' do
    expect(state_aid_calculator.state_aid_eur).to eq(Money.new(24_962_50, 'EUR'))
  end
end
