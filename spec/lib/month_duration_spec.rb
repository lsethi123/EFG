require 'spec_helper'

describe MonthDuration do
  describe '#==' do
    it 'is true when the total_months are the same' do
      expect(MonthDuration.new(30)).to eq(MonthDuration.new(30))
    end

    it 'is false when the total_months are not the same' do
      expect(MonthDuration.new(30)).not_to eq(MonthDuration.new(29))
    end
  end

  describe '#format' do
    it '1 month' do
      expect(MonthDuration.new(1).format).to eq('1 month')
    end

    it 'many months' do
      expect(MonthDuration.new(11).format).to eq('11 months')
    end

    it '1 year' do
      expect(MonthDuration.new(12).format).to eq('1 year')
    end

    it 'many years' do
      expect(MonthDuration.new(36).format).to eq('3 years')
    end

    it '1 year and 1 month' do
      expect(MonthDuration.new(13).format).to eq('1 year, 1 month')
    end

    it '1 year and many months' do
      expect(MonthDuration.new(15).format).to eq('1 year, 3 months')
    end

    it 'many years and 1 month' do
      expect(MonthDuration.new(37).format).to eq('3 years, 1 month')
    end

    it 'many years and many month' do
      expect(MonthDuration.new(47).format).to eq('3 years, 11 months')
    end
  end

  describe "comparable" do
    it "should have correct < behaviour" do
      expect(MonthDuration.new(3) < MonthDuration.new(4)).to eql(true)
    end

    it "should have correct > behaviour" do
      expect(MonthDuration.new(10) > MonthDuration.new(4)).to eql(true)
    end

    it "should have the correct between? behaviour" do
      expect(MonthDuration.new(2)).not_to be_between(MonthDuration.new(3), MonthDuration.new(5))
      expect(MonthDuration.new(3)).to be_between(MonthDuration.new(3), MonthDuration.new(5))
      expect(MonthDuration.new(4)).to be_between(MonthDuration.new(3), MonthDuration.new(5))
      expect(MonthDuration.new(5)).to be_between(MonthDuration.new(3), MonthDuration.new(5))
      expect(MonthDuration.new(6)).not_to be_between(MonthDuration.new(3), MonthDuration.new(5))
    end
  end
end
