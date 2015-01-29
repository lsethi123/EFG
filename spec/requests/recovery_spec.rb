# encoding: utf-8

require 'spec_helper'

describe 'loan recovery' do
  let(:current_user) { FactoryGirl.create(:lender_user, lender: loan.lender) }
  before { login_as(current_user, scope: :user) }

  context 'EFG' do
    let(:loan) {
      FactoryGirl.create(:loan, :settled,
        dti_demand_outstanding: Money.new(6_789_00),
        dti_interest: nil,
        settled_on: '1/5/12'
      )
    }

    [Loan::Settled, Loan::Recovered, Loan::Realised].each do |state|
      context "with state #{state}" do
        before do
          loan.update_attribute :state, state
        end

        it 'creates a loan recovery' do
          visit loan_path(loan)
          click_link 'Recovery Made'

          page.should have_content('£6,789.00')
          page.should_not have_button('Submit')

          expect {
            fill_in_valid_efg_recovery_details
            click_button 'Calculate'

            page.should have_content('£1,500.00')
            page.should have_content('£1,125.00')
          }.not_to change(Recovery, :count)

          expect {
            click_button 'Submit'
          }.to change(Recovery, :count).by(1)

          verify_recovery_and_loan

          current_path.should == loan_path(loan)
        end
      end
    end

    context 'with invalid values' do
      it 'does not continue' do
        visit loan_path(loan)
        click_link 'Recovery Made'

        expect {
          fill_in_valid_efg_recovery_details
          click_button 'Calculate'
        }.not_to change(Recovery, :count)

        expect {
          # clear recovery values
          fill_in 'recovery_recovered_on', with: ''
          fill_in 'recovery_outstanding_non_efg_debt', with: ''
          fill_in 'recovery_non_linked_security_proceeds', with: ''
          fill_in 'recovery_linked_security_proceeds', with: ''
          click_button 'Submit'
        }.not_to change(Recovery, :count)

        current_path.should == loan_recoveries_path(loan)
      end
    end
  end

  context 'SFLG' do
    let(:loan) {
      FactoryGirl.create(:loan, :sflg, :settled,
        dti_amount_claimed: Money.new(75_000_68),
        dti_interest: Money.new(10_000_34),
        dti_demand_outstanding: Money.new(90_000_57),
        settled_on: '1/5/12'
      )
    }

    before do
      FactoryGirl.create(:recovery, loan: loan, amount_due_to_dti: Money.new(66_61))
      FactoryGirl.create(:recovery, loan: loan, amount_due_to_dti: Money.new(19_55))
    end

    it 'creates a loan recovery' do
      visit loan_path(loan)
      click_link 'Recovery Made'

      page.should have_content('£100,000.91')
      page.should have_content('£86.16')
      page.should_not have_button('Submit')

      fill_in_valid_sflg_recovery_details

      expect {
        click_button 'Calculate'
      }.not_to change(Recovery, :count)

      page.should have_content('£175.28')
      page.should have_content('£976.28')

      expect {
        click_button 'Submit'
      }.to change(Recovery, :count).by(1)

      recovery = Recovery.last
      recovery.loan.should == loan
      recovery.seq.should == 2
      recovery.recovered_on.should == Date.current
      recovery.total_proceeds_recovered.should == Money.new(100_000_91)
      recovery.total_liabilities_behind.should == Money.new(123_00)
      recovery.total_liabilities_after_demand.should == Money.new(234_00)
      recovery.additional_interest_accrued.should == Money.new(345_00)
      recovery.additional_break_costs.should == Money.new(456_00)
      recovery.amount_due_to_dti.should == Money.new(976_28)

      loan.reload
      loan.state.should == Loan::Recovered
      loan.recovery_on.should == Date.current
      loan.modified_by.should == current_user

      current_path.should == loan_path(loan)
    end
  end

  context 'Legacy SFLG' do
    let(:loan) {
      FactoryGirl.create(:loan, :legacy_sflg, :settled,
        dti_amount_claimed: Money.new(3_375_00),
        dti_demand_outstanding: Money.new(4_400_00),
        dti_interest: Money.new(100_00),
        settled_on: '1/5/12'
      )
    }

    it 'creates a loan recovery' do
      visit loan_path(loan)
      click_link 'Recovery Made'

      page.should have_content('£2,531.25')
      page.should_not have_button('Submit')

      fill_in 'recovery_recovered_on', with: '1/5/12'
      fill_in 'recovery_total_liabilities_behind', with: '£123'
      fill_in 'recovery_total_liabilities_after_demand', with: '£234'
      fill_in 'recovery_additional_interest_accrued', with: '£345'
      fill_in 'recovery_additional_break_costs', with: '£456'

      expect {
        click_button 'Calculate'
      }.not_to change(Recovery, :count)

      page.should have_content('£170.83')
      page.should have_content('£971.83')

      expect {
        click_button 'Submit'
      }.to change(Recovery, :count).by(1)

      recovery = Recovery.last
      recovery.loan.should == loan
      recovery.seq.should == 0
      recovery.recovered_on.should == Date.new(2012, 5, 1)
      recovery.total_proceeds_recovered.should == Money.new(2_531_25)
      recovery.total_liabilities_behind.should == Money.new(123_00)
      recovery.total_liabilities_after_demand.should == Money.new(234_00)
      recovery.additional_interest_accrued.should == Money.new(345_00)
      recovery.additional_break_costs.should == Money.new(456_00)
      recovery.amount_due_to_dti.should == Money.new(971_83)

      loan.reload
      loan.state.should == Loan::Recovered
      loan.recovery_on.should == Date.new(2012, 5, 1)
      loan.modified_by.should == current_user

      current_path.should == loan_path(loan)
    end
  end

  private

    def verify_recovery_and_loan
      recovery = Recovery.last
      recovery.loan.should == loan
      recovery.seq.should == 0
      recovery.recovered_on.should == Date.current
      recovery.total_proceeds_recovered.should == Money.new(6_789_00)
      recovery.outstanding_non_efg_debt.should == Money.new(2_500_00)
      recovery.non_linked_security_proceeds.should == Money.new(3_000_00)
      recovery.linked_security_proceeds.should == Money.new(1_000_00)
      recovery.realisations_attributable.should == Money.new(1_500_00)
      recovery.amount_due_to_dti.should == Money.new(1_125_00)

      loan.reload
      loan.state.should == Loan::Recovered
      loan.recovery_on.should == Date.current
      loan.modified_by.should == current_user
    end
end
