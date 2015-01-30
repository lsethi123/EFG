# encoding: utf-8
require 'spec_helper'

describe EligibilityValidator do
  let(:klass) {
    Class.new do
      def self.name; 'Klass'; end
      include ActiveModel::Validations
      validates_with EligibilityValidator
    end
  }

  let(:collateral_exhausted) { true }
  let(:not_insolvent) { true }
  let(:previous_borrowing) { true }
  let(:private_residence_charge_required) { false }
  let(:reason) { double(eligible?: true) }
  let(:sic) { double(eligible?: true) }
  let(:trading_date) { Date.current }
  let(:viable_proposition) { true }
  let(:would_you_lend) { true }

  subject(:record) { klass.new }

  before do
    allow(record).to receive_messages(
      collateral_exhausted: collateral_exhausted,
      not_insolvent: not_insolvent,
      previous_borrowing: previous_borrowing,
      private_residence_charge_required: private_residence_charge_required,
      reason: reason,
      reason_id: nil,
      sic: sic,
      sic_code: nil,
      trading_date: trading_date,
      viable_proposition: viable_proposition,
      would_you_lend: would_you_lend
    )
  end

  context 'when everything is hunky dory' do
    it { should be_valid }
  end

  context 'when collateral_exhausted is false' do
    let(:collateral_exhausted) { false }

    it { should_not be_valid }
  end

  context 'when not_insolvent is false' do
    let(:not_insolvent) { false }

    it { should_not be_valid }
  end

  context 'when previous borrowing + the amount is not greater than £1,000,000' do
    let(:previous_borrowing) { false }

    it { should_not be_valid }
  end

  context 'when private_residence_charge_required is true' do
    let(:private_residence_charge_required) { true }

    it { should_not be_valid }
  end

  context 'when the reason is ineligible' do
    let(:reason) { double(eligible?: false) }

    it { should_not be_valid }
  end

  context 'when the SIC code is ineligible' do
    let(:sic) { double(eligible?: false) }

    it { should_not be_valid }
  end

  context 'when the trading_date is nil' do
    let(:trading_date) { nil }

    it { should_not be_valid }
  end

  context 'when the trading_date is more than 6 months in the future' do
    let(:trading_date) { 6.months.from_now.advance(days: 1) }

    it { should_not be_valid }
  end

  context 'when would_you_lend is false' do
    let(:would_you_lend) { false }

    it { should_not be_valid }
  end

  context 'when viable_proposition is false' do
    let(:viable_proposition) { false }

    it { should_not be_valid }
  end
end
