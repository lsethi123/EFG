require 'spec_helper'

describe 'Demanded Amount Data Correction' do
  include DataCorrectionSpecHelper

  context 'with a guaranteed loan' do
    let(:loan) { FactoryGirl.create(:loan, :guaranteed, lender: current_user.lender) }

    it 'cannot change the demanded amount' do
      visit_data_corrections
      page.should_not have_content('Demanded Amount')
    end
  end

  context 'with a demanded loan' do
    before do
      visit_data_corrections
      click_link 'Demanded Amount'
    end

    context 'with an EFG loan' do
      let(:loan) { FactoryGirl.create(:loan, :guaranteed, :demanded, lender: current_user.lender, dti_demand_outstanding: Money.new(1_000_00)) }

      it 'can update demanded_amount' do
        page.should_not have_css('#data_correction_demanded_interest')

        fill_in 'demanded_amount', '2000'
        click_button 'Submit'

        data_correction = loan.data_corrections.last!
        data_correction.old_dti_demand_outstanding.should == Money.new(1_000_00)
        data_correction.dti_demand_outstanding.should == Money.new(2_000_00)
        data_correction.change_type.should == ChangeType::DataCorrection
        data_correction.date_of_change.should == Date.current
        data_correction.modified_date.should == Date.current
        data_correction.created_by.should == current_user

        loan.reload
        loan.dti_demand_outstanding.should == Money.new(2_000_00)
        loan.modified_by.should == current_user
      end
    end

    [:sflg, :legacy_sflg].each do |type|
      context "with a #{type} loan" do
        let(:loan) { FactoryGirl.create(:loan, type, :guaranteed, :demanded, lender: current_user.lender, dti_demand_outstanding: Money.new(1_000_00), dti_interest: Money.new(100_00)) }

        it 'can update both amount and interest' do
          fill_in 'demanded_amount', '2000'
          fill_in 'demanded_interest', '1000'
          click_button 'Submit'

          data_correction = loan.data_corrections.last!
          data_correction.old_dti_demand_outstanding.should == Money.new(1_000_00)
          data_correction.dti_demand_outstanding.should == Money.new(2_000_00)
          data_correction.old_dti_interest.should == Money.new(100_00)
          data_correction.dti_interest.should == Money.new(1_000_00)
          data_correction.change_type.should == ChangeType::DataCorrection
          data_correction.date_of_change.should == Date.current
          data_correction.modified_date.should == Date.current
          data_correction.created_by.should == current_user

          loan.reload
          loan.dti_demand_outstanding.should == Money.new(2_000_00)
          loan.dti_interest.should == Money.new(1_000_00)
          loan.modified_by.should == current_user
        end
      end
    end
  end
end
