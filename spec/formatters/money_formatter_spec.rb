require 'spec_helper'

describe MoneyFormatter.new do
  subject { MoneyFormatter.new }

  describe '.format' do
    it 'returns a Money object' do
      expect(subject.format(12345)).to eq(Money.new(12345))
    end

    it 'does not return a zero-value Money object' do
      expect(subject.format(nil)).to be_nil
    end
  end

  describe '.parse' do
    it 'returns an integer of pence' do
      expect(subject.parse('123.45')).to eq(12345)
    end

    it 'returns nil for a blank value' do
      expect(subject.parse('')).to be_nil
    end
  end
end
