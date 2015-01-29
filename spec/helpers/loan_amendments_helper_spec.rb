require 'spec_helper'

describe LoanAmendmentsHelper do
  describe "#format_amendment_value" do
    context "RepaymentFrequency" do
      let(:value) { RepaymentFrequency::Annually }
      subject { helper.format_amendment_value(value) }
      it { should == 'Annually' }
    end
  end
end
