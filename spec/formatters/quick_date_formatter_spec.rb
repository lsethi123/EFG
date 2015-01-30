require 'spec_helper'

describe QuickDateFormatter do
  describe '.parse' do
    it 'correctly parses dd/mm/yyyy' do
      expect(QuickDateFormatter.parse('11/1/2011')).to eq(Date.new(2011, 1, 11))
    end

    it 'correctly parses dd/mm/yy' do
      expect(QuickDateFormatter.parse('11/1/11')).to eq(Date.new(2011, 1, 11))
    end

    it 'allows a date from the 90s' do
      expect(QuickDateFormatter.parse('3/2/1995')).to eq(Date.new(1995, 2, 3))
    end

    it 'allows the date 1599' do
      expect(QuickDateFormatter.parse('3/2/1599')).to eq(Date.new(1599, 2, 3))
    end

    it 'does not blow up for a nil value' do
      expect(QuickDateFormatter.parse(nil)).to be_nil
    end

    it 'does not blow up for a blank value' do
      expect(QuickDateFormatter.parse('')).to be_nil
    end

    it 'does not blow up for an incorrectly formatted date' do
      expect(QuickDateFormatter.parse('2008/01/01')).to be_nil
    end

    it 'does not blow up when the wrong number of days/month is entered' do
      expect(QuickDateFormatter.parse('31/9/2012')).to be_nil
    end
  end
end
