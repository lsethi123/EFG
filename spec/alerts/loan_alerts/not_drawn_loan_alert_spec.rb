require 'spec_helper'

describe LoanAlerts::NotDrawnLoanAlert do
  describe "#start_date" do
    it "should be 6 months ago + an additional 10 working days" do
      Timecop.freeze(2012, 11, 20) do
        expect(LoanAlerts::NotDrawnLoanAlert.start_date).to eq(Date.new(2012, 5, 7))
      end
    end
  end
end
