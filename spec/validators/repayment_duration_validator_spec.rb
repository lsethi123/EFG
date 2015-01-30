require 'spec_helper'

describe RepaymentDurationValidator do
  let(:klass) {
    Class.new do
      def self.name; 'Klass'; end
      include ActiveModel::Validations
      validates_with RepaymentDurationValidator
    end
  }

  let(:lending_limit) { FactoryGirl.build(:lending_limit) }
  let(:loan) { FactoryGirl.build(:loan, lending_limit: lending_limit, loan_category_id: loan_category_id) }
  let(:loan_category_id) { LoanCategory::TypeA.id }
  let(:repayment_duration) { MonthDuration.new(total_months) }

  subject(:record) { klass.new }

  before do
    allow(record).to receive_messages(
      loan: loan,
      repayment_duration: repayment_duration
    )
  end

  context 'when there is no repayment_duration' do
    let(:repayment_duration) { nil }

    it { should_not be_valid }
  end

  context 'when the repayment duration is less than 3 months' do
    let(:total_months) { 2 }

    it { should_not be_valid }
  end

  context 'when the repayment duration is longer than 10 years' do
    let(:total_months) { 121 }

    it { should_not be_valid }
  end

  context 'for a Type F loan' do
    let(:loan_category_id) { LoanCategory::TypeF.id }

    context 'when the repayment duration is longer than 3 years' do
      let(:total_months) { 37 }

      it { should_not be_valid }
    end
  end

  context 'phase 5' do
    let(:lending_limit) { FactoryGirl.build(:lending_limit, :phase_5) }

    context 'Type E' do
      let(:loan_category_id) { LoanCategory::TypeE.id }

      context 'when the repayment duration is 2 years or shorter' do
        let(:total_months) { 24 }

        it { should be_valid }
      end

      context 'when the repayment duration is >= 2 years' do
        let(:total_months) { 25 }

        it { should_not be_valid }
      end
    end
  end

  context 'phase 6' do
    let(:lending_limit) { FactoryGirl.build(:lending_limit, :phase_6) }

    context 'Type E' do
      let(:loan_category_id) { LoanCategory::TypeE.id }

      context 'when the repayment duration is 3 years or shorter' do
        let(:total_months) { 36 }

        it { should be_valid }
      end

      context 'when the repayment duration is >= 3 years' do
        let(:total_months) { 37 }

        it { should_not be_valid }
      end
    end
  end
end
