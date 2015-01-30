require 'spec_helper'

describe 'data correction' do
  include DataCorrectionSpecHelper

  describe 'Data Correction button' do
    [:guaranteed, :lender_demand, :demanded].each do |state|
      let(:loan) { FactoryGirl.create(:loan, state, lender: current_user.lender) }

      it "is visible when #{state}" do
        visit loan_path(loan)
        expect(page).to have_link('Data Correction')
      end
    end
  end
end
