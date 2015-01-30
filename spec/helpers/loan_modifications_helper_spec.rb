require 'spec_helper'

describe LoanModificationsHelper do
  describe "#format_modification_value" do
    context "RepaymentFrequency" do
      let(:value) { RepaymentFrequency::Annually }
      subject { helper.format_modification_value(value) }
      it { should eq('Annually') }
    end
  end
end
