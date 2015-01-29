require 'spec_helper'

describe LoanAmendmentPresenter do

  let(:loan) { FactoryGirl.create(:loan, :guaranteed) }

  let(:params) { { id: amendment.id, type: 'loan_modifications' } }

  subject(:presenter) { LoanAmendmentPresenter.new(loan, params) }

  describe "::for_loan" do
    let(:initial_draw_change) { loan.initial_draw_change }

    let!(:lump_sum_repayment) {
      FactoryGirl.create(:loan_change, :lump_sum_repayment,
        loan: loan, date_of_change: 2.days.from_now
      )
    }

    let!(:data_correction) {
      FactoryGirl.create(:data_correction,
        loan: loan, date_of_change: 1.day.from_now
      )
    }

    let!(:excluded_amendment) { FactoryGirl.create(:loan_change, :lump_sum_repayment) }

    let(:presenters) { LoanAmendmentPresenter.for_loan(loan) }

    it "returns collection of presenters for each amendment" do
      presenters.map(&:amendment).should match_array([initial_draw_change, data_correction, lump_sum_repayment])
    end
  end

  describe "#changes" do
    context "data correction" do
      let(:params) { { id: amendment.id, type: 'data_corrections' } }

      describe "with post code change" do
        let(:data_correction_changes) { { postcode: [loan.postcode.to_s, 'E15 1LU'] } }

        let(:amendment) {
          FactoryGirl.create(:data_correction,
            loan: loan,
            data_correction_changes: data_correction_changes)
        }

        it "returns collection with attribute change for old and new postcode" do
          presenter.changes.size.should == 1

          attribute_change = presenter.changes.first
          attribute_change.old_attribute.should == 'old_postcode'
          attribute_change.old_value.should == loan.postcode
          attribute_change.attribute.should == 'postcode'
          attribute_change.value.should == 'E15 1LU'
        end
      end

      describe "with lending limit change" do
        let(:lender) { loan.lender }
        let(:lending_limit_1) { FactoryGirl.create(:lending_limit, lender: lender) }
        let(:lending_limit_2) { FactoryGirl.create(:lending_limit, lender: lender) }
        let(:data_correction_changes) {
          { lending_limit_id: [lending_limit_1.id, lending_limit_2.id] }
        }
        let(:amendment) {
          FactoryGirl.create(:data_correction,
            loan: loan,
            data_correction_changes: data_correction_changes)
        }

        it "returns collection with attribute change for old and new lending limit" do
          presenter.changes.size.should == 1

          attribute_change = presenter.changes.first
          attribute_change.old_attribute.should == 'old_lending_limit'
          attribute_change.old_value.should == lending_limit_1
          attribute_change.attribute.should == 'lending_limit'
          attribute_change.value.should == lending_limit_2
        end
      end
    end

    context "loan_modifications" do
      let(:params) { { id: amendment.id, type: 'loan_modifications' } }

      let(:amendment) { FactoryGirl.create(:loan_change, :repayment_frequency, loan: loan) }

      it 'contains only fields that have a value' do
        presenter.old_repayment_frequency_id = RepaymentFrequency::Monthly.id
        presenter.repayment_frequency_id = RepaymentFrequency::Annually.id

        presenter.changes.size.should == 1
        attribute_change = presenter.changes.first
        attribute_change.old_attribute.should == 'old_repayment_frequency'
        attribute_change.old_value.should == RepaymentFrequency::Monthly
        attribute_change.attribute.should == 'repayment_frequency'
        attribute_change.value.should == RepaymentFrequency::Annually
      end

      it 'contains fields where the old value was NULL' do
        presenter.old_repayment_frequency_id = nil
        presenter.repayment_frequency_id = RepaymentFrequency::Quarterly.id

        presenter.changes.size.should == 1
        attribute_change = presenter.changes.first
        attribute_change.old_attribute.should == 'old_repayment_frequency'
        attribute_change.old_value.should == nil
        attribute_change.attribute.should == 'repayment_frequency'
        attribute_change.value.should == RepaymentFrequency::Quarterly
      end
    end
  end

  describe "#drawn_amount?" do
    context "with drawn amount" do
      let(:amendment) { loan.initial_draw_change }

      it "returns true" do
        presenter.drawn_amount?.should == true
      end
    end

    context "without drawn amount" do
      let(:amendment) { FactoryGirl.create(:loan_change, loan: loan, amount_drawn: nil) }

      it "returns false" do
        presenter.drawn_amount?.should == false
      end
    end
  end

  describe "#lump_sum_repayment?" do
    context "with lump sum repayment" do
      let(:amendment) { FactoryGirl.create(:loan_change, :lump_sum_repayment, loan: loan) }

      it "returns true" do
        presenter.lump_sum_repayment?.should == true
      end
    end

    context "without lump sum repayment" do
      let(:amendment) { FactoryGirl.create(:loan_change, loan: loan) }

      it "returns false" do
        presenter.lump_sum_repayment?.should == false
      end
    end
  end

end
