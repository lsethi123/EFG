require 'spec_helper'

describe DemandedAmountDataCorrection do
  describe 'validations' do
    let(:loan) { FactoryGirl.create(:loan, :guaranteed, :demanded, dti_demand_outstanding: Money.new(1_000_00), dti_interest: Money.new(100_00)) }
    let(:presenter) { FactoryGirl.build(:demanded_amount_data_correction) }

    it 'has a valid factory' do
      expect(presenter).to be_valid
    end

    it 'strictly requires the loan to be Demanded' do
      expect {
        presenter.loan.state = Loan::Guaranteed
        presenter.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'requires a change' do
      presenter.demanded_amount = ''
      presenter.demanded_interest = ''
      expect(presenter).not_to be_valid
    end

    context '#demanded_amount=' do
      let(:presenter) { FactoryGirl.build(:demanded_amount_data_correction, loan: loan) }

      it 'must not be negative' do
        presenter.demanded_amount = Money.new(-1)
        expect(presenter).not_to be_valid
      end

      it 'must not be the same value' do
        presenter.demanded_amount = loan.dti_demand_outstanding
        expect(presenter).not_to be_valid
      end

      it 'must not be greater than the cumulative_drawn_amount' do
        presenter.demanded_amount = loan.cumulative_drawn_amount + Money.new(1)
        expect(presenter).not_to be_valid
      end
    end

    context '#demanded_interest=' do
      let(:presenter) { FactoryGirl.build(:demanded_amount_data_correction, loan: loan) }

      it 'must not be negative' do
        presenter.demanded_interest = Money.new(-1)
        expect(presenter).not_to be_valid
      end

      it 'must not be the same value' do
        presenter.demanded_interest = loan.dti_interest
        expect(presenter).not_to be_valid
      end

      it 'must be lte to original loan amount when amount is not being changed' do
        presenter.demanded_interest = loan.amount + Money.new(1)
        expect(presenter).not_to be_valid
      end
    end
  end

  describe '#save' do
    let(:user) { FactoryGirl.create(:lender_user) }
    let(:presenter) { FactoryGirl.build(:demanded_amount_data_correction, created_by: user, loan: loan) }

    context 'EFG loan' do
      let(:loan) { FactoryGirl.create(:loan, :guaranteed, :demanded, dti_demand_outstanding: Money.new(1_000_00), dti_interest: nil) }

      context 'success' do
        it 'creates a DataCorrection and updates the loan' do
          presenter.demanded_amount = '1,234.56'
          presenter.demanded_interest = '123.45' # ignored
          expect(presenter.save).to eq(true)

          data_correction = loan.data_corrections.last!
          expect(data_correction.created_by).to eq(user)
          expect(data_correction.dti_demand_out_amount).to eq(Money.new(1_234_56))
          expect(data_correction.old_dti_demand_out_amount).to eq(Money.new(1_000_00))
          expect(data_correction.dti_demand_interest).to be_nil
          expect(data_correction.old_dti_demand_interest).to be_nil

          loan.reload
          expect(loan.dti_demand_outstanding).to eq(Money.new(1_234_56))
          expect(loan.dti_interest).to be_nil
          expect(loan.last_modified_at).not_to eq(1.year.ago)
          expect(loan.modified_by).to eq(user)
        end
      end

      context 'failure' do
        it 'does not update the loan' do
          presenter.demanded_amount = ''
          expect(presenter.save).to eq(false)

          loan.reload
          expect(loan.dti_demand_outstanding).to eq(Money.new(1_000_00))
        end
      end
    end

    context 'non-EFG loan' do
      let(:loan) { FactoryGirl.create(:loan, :sflg, :guaranteed, :demanded, dti_demand_outstanding: Money.new(1_000_00), dti_interest: Money.new(100_00)) }

      context 'success' do
        it 'also updates demand_interest' do
          presenter.demanded_amount = '1,234.56'
          presenter.demanded_interest = '123.45'
          expect(presenter.save).to eq(true)

          data_correction = loan.data_corrections.last!
          expect(data_correction.dti_demand_out_amount).to eq(Money.new(1_234_56))
          expect(data_correction.old_dti_demand_out_amount).to eq(Money.new(1_000_00))
          expect(data_correction.dti_demand_interest).to eq(Money.new(123_45))
          expect(data_correction.old_dti_demand_interest).to eq(Money.new(100_00))

          loan.reload
          expect(loan.dti_demand_outstanding).to eq(Money.new(1_234_56))
          expect(loan.dti_interest).to eq(Money.new(123_45))
        end

        it 'can update values to zero' do
          presenter.demanded_amount = '0'
          presenter.demanded_interest = '0'
          expect(presenter.save).to eq(true)

          loan.reload
          expect(loan.dti_demand_outstanding).to eq(Money.new(0))
          expect(loan.dti_interest).to eq(Money.new(0))
        end
      end

      context 'failure' do
        it 'does not update the loan' do
          presenter.demanded_amount = ''
          presenter.demanded_interest = ''
          expect(presenter.save).to eq(false)

          loan.reload
          expect(loan.dti_demand_outstanding).to eq(Money.new(1_000_00))
          expect(loan.dti_interest).to eq(Money.new(100_00))
        end
      end
    end
  end
end
