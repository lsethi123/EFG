require 'spec_helper'

describe Phase6StateAidCalculator do
  let(:state_aid_calculator) { Phase6StateAidCalculator.new(loan) }
  subject { state_aid_calculator.state_aid_eur }

  context "4 year loan" do
    let(:loan) {
      double(:loan,
        amount: Money.new(750_000_00),
        repayment_duration: MonthDuration.new(48),
        euro_conversion_rate: BigDecimal.new('1.20744')
      )
    }

    it { should eq(Money.new(96_595_20, 'EUR')) }
  end

  context "8 year loan" do
    let(:loan) {
      double(:loan,
        amount: Money.new(250_000_00),
        repayment_duration: MonthDuration.new(96),
        euro_conversion_rate: BigDecimal.new('1.20744')
      )
    }

    it { should eq(Money.new(64_396_80, 'EUR')) }
  end

  context "10 year loan" do
    let(:loan) {
      double(:loan,
        amount: Money.new(100_000_00),
        repayment_duration: MonthDuration.new(120),
        euro_conversion_rate: BigDecimal.new('1.20744')
      )
    }

    it { should eq(Money.new(32_198_41, 'EUR')) }
  end

  context 'nil amount' do
    let(:loan) {
      double(:loan,
        amount: nil,
        repayment_duration: MonthDuration.new(48),
        euro_conversion_rate: BigDecimal.new('1.20744')
      )
    }

    it { should eq(Money.new(0, 'EUR')) }
  end

  context 'nil repayment_duration' do
    let(:loan) {
      double(:loan,
        amount: Money.new(100_000_00),
        repayment_duration: nil,
        euro_conversion_rate: BigDecimal.new('1.20744')
      )
    }

    it { should eq(Money.new(0, 'EUR')) }
  end
end
