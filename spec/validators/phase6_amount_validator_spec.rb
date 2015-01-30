# encoding: utf-8
require 'spec_helper'

describe Phase6AmountValidator do
  let(:klass) {
    Class.new do
      def self.name; 'Klass'; end
      include ActiveModel::Validations
      validates_with Phase6AmountValidator
    end
  }
  subject(:record) { klass.new }

  before do
    allow(record).to receive_messages(
      amount: amount,
      repayment_duration: repayment_duration
    )
  end

  context 'when amount and repayment_duration are nil' do
    let(:amount) { nil }
    let(:repayment_duration) { nil }

    it { should be_valid }
  end

  context 'when amount is nil' do
    let(:amount) { nil }
    let(:repayment_duration) { MonthDuration.new(60) }

    it { should be_valid }
  end

  context 'when repayment_duration is nil' do
    let(:amount) { Money.new(10_000_00) }
    let(:repayment_duration) { nil }

    it { should be_valid }
  end

  context 'when amount is greater than £600,000 and repayment duration is longer than 5 years' do
    let(:amount) { Money.new(600_000_01) }
    let(:repayment_duration) { MonthDuration.new(61) }

    it { should_not be_valid }
  end

  context 'when amount is £600,000 and repayment_duration is 5 years' do
    let(:amount) { Money.new(600_000_00) }
    let(:repayment_duration) { MonthDuration.new(60) }

    it { should be_valid }
  end
end
