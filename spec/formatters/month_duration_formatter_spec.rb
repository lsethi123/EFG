require 'spec_helper'

describe MonthDurationFormatter do
  describe ".parse" do
    it "should convert the hash into the total number of months" do
      duration = MonthDurationFormatter.parse(years: 1, months: 11)
      expect(duration).to eq(23)
    end

    it "should return nil with blank values" do
      expect(MonthDurationFormatter.parse(years: '', months: '')).to be_nil
    end

    it "should return nil with a blank hash" do
      expect(MonthDurationFormatter.parse({})).to be_nil
    end

    it "should return argument if an integer" do
      expect(MonthDurationFormatter.parse(60)).to eq(60)
    end
  end

  describe ".format" do
    it "should return nil if total_months is nil" do
      expect(MonthDurationFormatter.format(nil)).to be_nil
    end

    it 'should divide a number of months into years and months' do
      duration = MonthDurationFormatter.format(18)
      expect(duration.years).to eq(1)
      expect(duration.months).to eq(6)
      expect(duration.total_months).to eq(18)
    end

    it "should handle 0" do
      duration = MonthDurationFormatter.format(0)
      expect(duration.years).to eq(0)
      expect(duration.months).to eq(0)
      expect(duration.total_months).to eq(0)
    end
  end
end
