shared_examples_for 'a loan transfer' do

  describe 'validations' do

    it 'should have a valid factory' do
      expect(loan_transfer).to be_valid
    end

    it 'must have a reference' do
      loan_transfer.reference = nil
      expect(loan_transfer).not_to be_valid
    end

    it 'must have an amount' do
      loan_transfer.amount = nil
      expect(loan_transfer).not_to be_valid
    end

    it 'must have a new amount' do
      loan_transfer.new_amount = nil
      expect(loan_transfer).not_to be_valid
    end

    it 'declaration signed must be true' do
      loan_transfer.declaration_signed = false
      expect(loan_transfer).not_to be_valid
    end

    it 'declaration signed must not be blank' do
      loan_transfer.declaration_signed = nil
      expect(loan_transfer).not_to be_valid
    end

    it 'must have a lender' do
      loan_transfer.lender = nil
      expect(loan_transfer).not_to be_valid
    end

  end

  describe '#save' do
    let(:original_loan) { loan.reload }

    let(:new_loan) { Loan.last }

    context 'when valid' do
      before(:each) do
        loan_transfer.save
      end

      it 'should transition original loan to repaid from transfer state' do
        expect(original_loan.state).to eq(Loan::RepaidFromTransfer)
      end

      it 'should assign new loan to lender requesting transfer' do
        expect(new_loan.lender).to eq(loan_transfer.lender)
      end

      it 'should create new loan with incremented reference number' do
        expect(new_loan.reference).to eq(reference_class.new(loan.reference).increment)
      end

      it 'should create new loan with state "incomplete"' do
        expect(new_loan.state).to eq(Loan::Incomplete)
      end

      it 'should create new loan with amount set to the specified new amount' do
        expect(new_loan.amount).to eq(loan_transfer.new_amount)
      end

      it 'should create new loan with no value for branch sort code' do
        expect(new_loan.sortcode).to be_blank
      end

      it 'should create new loan with repayment duration of 0' do
        expect(new_loan.repayment_duration).to eq(MonthDuration.new(0))
      end

      it 'should create new loan with no value for payment period' do
        expect(new_loan.repayment_frequency).to be_blank
      end

      it 'should create new loan with no value for maturity date' do
        expect(new_loan.maturity_date).to be_blank
      end

      it 'should create new loan with no value for generic fields' do
        (1..5).each do |num|
          expect(new_loan.send("generic#{num}")).to be_blank
        end
      end

      it 'should create new loan with no invoice' do
        expect(new_loan.invoice_id).to be_blank
      end

      it 'should create a new loan with no lender reference' do
        expect(new_loan.lender_reference).to be_blank
      end

      it 'should track which loan a transferred loan came from' do
        expect(new_loan.transferred_from_id).to eq(loan.id)
      end

      it 'should assign new loan to the newest active LendingLimit of the lender receiving transfer' do
        expect(new_loan.lending_limit).to eq(new_loan.lender.lending_limits.active.first)
      end

      it 'should nullify legacy_id field' do
        original_loan.legacy_id = 12345
        expect(new_loan.legacy_id).to be_nil
      end

      it 'should create new loan with modified by set to user requesting transfer' do
        expect(new_loan.modified_by).to eq(loan_transfer.modified_by)
      end

      it 'should create new loan with created by set to user requesting transfer' do
        expect(new_loan.created_by).to eq(loan_transfer.modified_by)
      end

      it 'should copy existing loan securities to new loan' do
        expect(original_loan.loan_security_types).not_to be_empty
        expect(new_loan.loan_security_types).to eq(original_loan.loan_security_types)
      end
    end

    context 'when new loan amount is greater than the amount of the loan being transferred' do
      before(:each) do
        loan_transfer.new_amount = loan.amount + Money.new(100)
      end

      it 'should return false' do
        expect(loan_transfer.save).to eq(false)
      end

      it 'should add error to base' do
        loan_transfer.save
        expect(loan_transfer.errors[:new_amount]).to include(error_string('new_amount.cannot_be_greater'))
      end
    end

    context 'when loan being transferred is not in state guaranteed, lender demand or repaid' do
      before(:each) do
        loan.update_attribute(:state, Loan::Eligible)
      end

      it "should return false" do
        expect(loan_transfer.save).to eq(false)
      end
    end

    context 'when loan being transferred belongs to lender requesting the transfer' do
      before(:each) do
        loan_transfer.lender = loan.lender
      end

      it "should return false" do
        expect(loan_transfer.save).to eq(false)
      end

      it "should add error to base" do
        loan_transfer.save
        expect(loan_transfer.errors[:base]).to include(error_string('base.cannot_transfer_own_loan'))
      end
    end

    context 'when the loan being transferred has already been transferred' do
      before(:each) do
        # create new loan with same reference of 'loan' but with a incremented version number
        # this means the loan has already been transferred
        incremented_reference = reference_class.new(loan.reference).increment
        FactoryGirl.create(:loan, :repaid_from_transfer, reference: incremented_reference)
      end

      it "should return false" do
        expect(loan_transfer.save).to eq(false)
      end

      it "should add error to base" do
        loan_transfer.save
        expect(loan_transfer.errors[:base]).to include(error_string('base.cannot_be_transferred'))
      end
    end

    context 'when no matching loan is found' do
      before(:each) do
        loan_transfer.amount = Money.new(1000)
      end

      it "should return false" do
        expect(loan_transfer.save).to eq(false)
      end

      it "should add error to base" do
        loan_transfer.save
        expect(loan_transfer.errors[:base]).to include(error_string('base.cannot_be_transferred'))
      end
    end

    context 'when loan is an EFG loan' do
      let!(:loan) { FactoryGirl.create(:loan, :offered, :guaranteed, :with_premium_schedule) }

      it "should return false" do
        expect(loan_transfer.save).to eq(false)
      end

      it "should add error to base" do
        loan_transfer.save
        expect(loan_transfer.errors[:base]).to include(error_string('base.cannot_be_transferred'))
      end
    end

    context 'when lender making transfer can only access EFG scheme loans' do
      let!(:lender) { FactoryGirl.create(:lender, loan_scheme: Lender::EFG_SCHEME) }

      before(:each) do
        loan_transfer.lender = lender
      end

      it "should return false" do
        expect(loan_transfer.save).to eq(false)
      end

      it "should add error to base" do
        loan_transfer.save
        expect(loan_transfer.errors[:base]).to include(error_string('base.cannot_be_transferred'))
      end
    end
  end

  private

  def error_string(key)
    class_key = loan_transfer.class.to_s.underscore
    I18n.t("activemodel.errors.models.#{class_key}.attributes.#{key}")
  end

  def reference_class
    loan.legacy_loan? ? LegacyLoanReference : LoanReference
  end

end
