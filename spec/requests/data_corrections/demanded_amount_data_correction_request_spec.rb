require 'spec_helper'

describe 'Demanded Amount Data Correction' do
  include DataCorrectionSpecHelper

  context 'with a guaranteed loan' do
    let(:loan) { FactoryGirl.create(:loan, :guaranteed, lender: current_user.lender) }

    it 'cannot change the demanded amount' do
      visit_data_corrections
      expect(page).not_to have_content('Demanded Amount')
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
        expect(page).not_to have_css('#data_correction_demanded_interest')

        fill_in 'demanded_amount', '2000'
        click_button 'Submit'

        data_correction = loan.data_corrections.last!
        expect(data_correction.old_dti_demand_out_amount).to eq(Money.new(1_000_00))
        expect(data_correction.dti_demand_out_amount).to eq(Money.new(2_000_00))
        expect(data_correction.change_type).to eq(ChangeType::DataCorrection)
        expect(data_correction.date_of_change).to eq(Date.current)
        expect(data_correction.modified_date).to eq(Date.current)
        expect(data_correction.created_by).to eq(current_user)

        loan.reload
        expect(loan.dti_demand_outstanding).to eq(Money.new(2_000_00))
        expect(loan.modified_by).to eq(current_user)
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
          expect(data_correction.old_dti_demand_out_amount).to eq(Money.new(1_000_00))
          expect(data_correction.dti_demand_out_amount).to eq(Money.new(2_000_00))
          expect(data_correction.old_dti_demand_interest).to eq(Money.new(100_00))
          expect(data_correction.dti_demand_interest).to eq(Money.new(1_000_00))
          expect(data_correction.change_type).to eq(ChangeType::DataCorrection)
          expect(data_correction.date_of_change).to eq(Date.current)
          expect(data_correction.modified_date).to eq(Date.current)
          expect(data_correction.created_by).to eq(current_user)

          loan.reload
          expect(loan.dti_demand_outstanding).to eq(Money.new(2_000_00))
          expect(loan.dti_interest).to eq(Money.new(1_000_00))
          expect(loan.modified_by).to eq(current_user)
        end
      end
    end
  end
end
