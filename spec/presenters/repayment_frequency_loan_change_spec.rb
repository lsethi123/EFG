require 'spec_helper'

describe RepaymentFrequencyLoanChange do
  it_behaves_like 'LoanChangePresenter'

  describe "validations" do
    context "valid factory" do
      subject { FactoryGirl.build(:repayment_frequency_loan_change) }
      it { should be_valid }
    end

    context "without a repayment_frequency_id" do
      subject { FactoryGirl.build(:repayment_frequency_loan_change, repayment_frequency_id: nil) }
      it { should_not be_valid }
    end

    context "with an unknown repayment_frequency" do
      subject { FactoryGirl.build(:repayment_frequency_loan_change, repayment_frequency_id: 'unknown') }
      it { should_not be_valid }
    end

    context "without changing the repayment_frequency" do
      let(:repayment_frequency_id) { RepaymentFrequency::Annually.id }
      let(:loan) { FactoryGirl.create(:loan, :guaranteed, :with_premium_schedule, repayment_frequency_id: repayment_frequency_id) }
      subject { FactoryGirl.build(:repayment_frequency_loan_change, loan: loan, repayment_frequency_id: repayment_frequency_id) }
      it { should_not be_valid }
    end
  end

  describe "repayment_frequency_id=" do
    let(:presenter) { FactoryGirl.build(:repayment_frequency_loan_change) }
    before { presenter.repayment_frequency_id = value }
    subject { presenter.repayment_frequency_id }

    context "with number" do
      let(:value) { 1 }
      it { should == 1 }
    end

    context "with string" do
      let(:value) { '1' }
      it { should == 1 }
    end

    context "with blank" do
      let(:value) { ' ' }
      it { should == nil }
    end
  end

  describe '#save' do
    let(:user) { FactoryGirl.create(:lender_user) }
    let(:loan) { FactoryGirl.create(:loan, :guaranteed, :with_premium_schedule, repayment_duration: 60, repayment_frequency_id: RepaymentFrequency::Annually.id) }
    let(:presenter) { FactoryGirl.build(:repayment_frequency_loan_change, created_by: user, loan: loan) }

    context 'success' do
      before do
        loan.initial_draw_change.update_column :date_of_change, Date.new(2013, 2)
      end

      it 'creates a LoanChange and updates the loan' do
        presenter.repayment_frequency_id = RepaymentFrequency::Quarterly.id

        Timecop.freeze(2013, 3, 1) do
          presenter.save.should == true
        end

        loan_change = loan.loan_changes.last!
        loan_change.change_type.should == ChangeType::RepaymentFrequency
        loan_change.repayment_frequency_id.should == RepaymentFrequency::Quarterly.id
        loan_change.old_repayment_frequency_id.should == RepaymentFrequency::Annually.id
        loan_change.created_by.should == user

        loan.reload
        loan.modified_by.should == user
        loan.repayment_frequency_id.should == RepaymentFrequency::Quarterly.id

        premium_schedule = loan.premium_schedules.last!
        premium_schedule.premium_cheque_month.should == '05/2013'
        premium_schedule.repayment_duration.should == 57
      end
    end

    context 'failure' do
      it 'does not update loan' do
        presenter.repayment_frequency_id = nil
        presenter.save.should == false

        loan.reload
        loan.modified_by.should_not == user
        loan.repayment_frequency_id.should == RepaymentFrequency::Annually.id
      end
    end
  end
end
