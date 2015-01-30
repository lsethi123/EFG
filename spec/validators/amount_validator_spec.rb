require 'spec_helper'

describe AmountValidator do
  let(:klass) {
    Class.new do
      def self.name; 'Klass'; end
      include ActiveModel::Validations
      validates_with AmountValidator, maximum: Money.new(1_000_000_00), minimum: Money.new(1_000_00)
    end
  }
  subject(:record) { klass.new }

  before do
    allow(record).to receive_messages(amount: amount)
  end

  context 'when amount is nil' do
    let(:amount) { nil }

    it { should_not be_valid }
  end

  context 'when amount is blank' do
    let(:amount) { '' }

    it { should_not be_valid }
  end

  context 'when amount is less than minimum' do
    let(:amount) { Money.new(999_99) }

    it { should_not be_valid }
  end

  context 'when amount is greater than maximum' do
    let(:amount) { Money.new(1_000_000_01) }

    it { should_not be_valid }
  end

  context 'when amount is between minimum and maximum' do
    let(:amount) { Money.new(1_000_00) }

    it { should be_valid }
  end
end
