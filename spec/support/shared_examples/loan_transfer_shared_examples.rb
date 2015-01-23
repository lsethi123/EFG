shared_examples_for 'a loan transfer' do

  describe 'validations' do

    it 'should have a valid factory' do
      loan_transfer.should be_valid
    end

    it 'must have a reference' do
      loan_transfer.reference = nil
      loan_transfer.should_not be_valid
    end

    it 'must have an amount' do
      loan_transfer.amount = nil
      loan_transfer.should_not be_valid
    end

    it 'must have a new amount' do
      loan_transfer.new_amount = nil
      loan_transfer.should_not be_valid
    end

    it 'declaration signed must be true' do
      loan_transfer.declaration_signed = false
      loan_transfer.should_not be_valid
    end

    it 'declaration signed must not be blank' do
      loan_transfer.declaration_signed = nil
      loan_transfer.should_not be_valid
    end

    it 'must have a lender' do
      loan_transfer.lender = nil
      loan_transfer.should_not be_valid
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
        original_loan.state.should == Loan::RepaidFromTransfer
      end

      it 'should assign new loan to lender requesting transfer' do
        new_loan.lender.should == loan_transfer.lender
      end

      it 'should create new loan with incremented reference number' do
        new_loan.reference.should == reference_class.new(loan.reference).increment
      end

      it 'should create new loan with state "incomplete"' do
        new_loan.state.should == Loan::Incomplete
      end

      it 'should create new loan with amount set to the specified new amount' do
        new_loan.amount.should == loan_transfer.new_amount
      end

      it 'should create new loan with no value for branch sort code' do
        new_loan.sortcode.should be_blank
      end

      it 'should create new loan with repayment duration of 0' do
        new_loan.repayment_duration.should == MonthDuration.new(0)
      end

      it 'should create new loan with no value for payment period' do
        new_loan.repayment_frequency.should be_blank
      end

      it 'should create new loan with no value for maturity date' do
        new_loan.maturity_date.should be_blank
      end

      it 'should create new loan with no value for sub-lender' do
        new_loan.sub_lender.should be_blank
      end

      it 'should create new loan with no value for generic fields' do
        (1..5).each do |num|
          new_loan.send("generic#{num}").should be_blank
        end
      end

      it 'should create new loan with no invoice' do
        new_loan.invoice_id.should be_blank
      end

      it 'should create a new loan with no lender reference' do
        new_loan.lender_reference.should be_blank
      end

      it 'should track which loan a transferred loan came from' do
        new_loan.transferred_from_id.should == loan.id
      end

      it 'should assign new loan to the newest active LendingLimit of the lender receiving transfer' do
        new_loan.lending_limit.should == new_loan.lender.lending_limits.active.first
      end

      it 'should nullify legacy_id field' do
        original_loan.legacy_id = 12345
        new_loan.legacy_id.should be_nil
      end

      it 'should create new loan with modified by set to user requesting transfer' do
        new_loan.modified_by.should == loan_transfer.modified_by
      end

      it 'should create new loan with created by set to user requesting transfer' do
        new_loan.created_by.should == loan_transfer.modified_by
      end

      it 'should copy existing loan securities to new loan' do
        original_loan.loan_security_types.should_not be_empty
        new_loan.loan_security_types.should == original_loan.loan_security_types
      end
    end

    context 'when new loan amount is greater than the amount of the loan being transferred' do
      before(:each) do
        loan_transfer.new_amount = loan.amount + Money.new(100)
      end

      it 'should return false' do
        loan_transfer.save.should == false
      end

      it 'should add error to base' do
        loan_transfer.save
        loan_transfer.errors[:new_amount].should include(error_string('new_amount.cannot_be_greater'))
      end
    end

    context 'when loan being transferred is not in state guaranteed, lender demand or repaid' do
      before(:each) do
        loan.update_attribute(:state, Loan::Eligible)
      end

      it "should return false" do
        loan_transfer.save.should == false
      end
    end

    context 'when loan being transferred belongs to lender requesting the transfer' do
      before(:each) do
        loan_transfer.lender = loan.lender
      end

      it "should return false" do
        loan_transfer.save.should == false
      end

      it "should add error to base" do
        loan_transfer.save
        loan_transfer.errors[:base].should include(error_string('base.cannot_transfer_own_loan'))
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
        loan_transfer.save.should == false
      end

      it "should add error to base" do
        loan_transfer.save
        loan_transfer.errors[:base].should include(error_string('base.cannot_be_transferred'))
      end
    end

    context 'when no matching loan is found' do
      before(:each) do
        loan_transfer.amount = Money.new(1000)
      end

      it "should return false" do
        loan_transfer.save.should == false
      end

      it "should add error to base" do
        loan_transfer.save
        loan_transfer.errors[:base].should include(error_string('base.cannot_be_transferred'))
      end
    end

    context 'when loan is an EFG loan' do
      let!(:loan) { FactoryGirl.create(:loan, :offered, :guaranteed, :with_premium_schedule) }

      it "should return false" do
        loan_transfer.save.should == false
      end

      it "should add error to base" do
        loan_transfer.save
        loan_transfer.errors[:base].should include(error_string('base.cannot_be_transferred'))
      end
    end

    context 'when lender making transfer can only access EFG scheme loans' do
      let!(:lender) { FactoryGirl.create(:lender, loan_scheme: Lender::EFG_SCHEME) }

      before(:each) do
        loan_transfer.lender = lender
      end

      it "should return false" do
        loan_transfer.save.should == false
      end

      it "should add error to base" do
        loan_transfer.save
        loan_transfer.errors[:base].should include(error_string('base.cannot_be_transferred'))
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
