require 'spec_helper'

describe SubLenderDataCorrection do
  let(:current_user) { FactoryGirl.create(:lender_user) }
  let(:data_correction) { FactoryGirl.build(:sub_lender_data_correction, loan: loan, created_by: current_user) }

  context "when lender has sub-lenders" do
    let!(:loan) { FactoryGirl.create(:loan, :guaranteed, lender: current_user.lender) }
    let!(:sub_lender) { FactoryGirl.create(:sub_lender, lender: loan.lender, name: 'ACME Sub-lender') }

    it_behaves_like 'loan updating data correction presenter', :sub_lender, 'ACME Sub-lender'

    it "must have a sub-lender" do
      data_correction.sub_lender = nil
      data_correction.should_not be_valid
      data_correction.should have(1).error_on(:sub_lender)
    end

    it "must have an allowed sub-lender" do
      data_correction.sub_lender = "not a valid sub lender for this lender"
      data_correction.should_not be_valid
      data_correction.should have(1).error_on(:sub_lender)
    end
  end

  context "when lender has no sub-lenders" do
    let!(:loan) { FactoryGirl.create(:loan, :guaranteed, lender: current_user.lender) }

    it "must have a blank sub_lender" do
      data_correction.sub_lender = 'ACME Sub-lender'
      data_correction.should_not be_valid
      data_correction.should have(1).error_on(:sub_lender)
    end
  end
end
