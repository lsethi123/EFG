require 'spec_helper'

describe LoanAlerts::Group do

  let(:loan1) { FactoryGirl.create(:loan) }

  let(:loan2) { FactoryGirl.create(:loan) }

  let(:loan3) { FactoryGirl.create(:loan) }

  let(:group) {
    loans = [ [loan1], [loan2], [loan3] ]
    LoanAlerts::Group.new(loans, :high, 1)
  }

  describe "#each_alert_by_day" do
    it "should yield a loan alerts entry for each day of loans" do
      group.each_alert_by_day do |yielded|
        expect(yielded).to be_instance_of(LoanAlerts::Entry)
      end
    end
  end

  describe "#class_name" do
    it "should return a HTML class name string based on the priority of the group" do
      expect(group.class_name).to eq('high-priority')
    end
  end

  describe "#total_loans" do
    it "should return the total number of loans in the group" do
      expect(group.total_loans).to eq(3)
    end
  end


end
