require 'spec_helper'
require 'verde_transfer'

describe VerdeTransfer do
  describe "#run" do
    let!(:system_user) { FactoryGirl.create(:system_user) }
    let(:original_lender) { FactoryGirl.create(:lender, name: "Original") }
    let(:new_lender) { FactoryGirl.create(:lender, name: "New") }
    let!(:original_lending_limit_1) { FactoryGirl.create(:lending_limit, lender: original_lender, name: 'A') }
    let!(:original_lending_limit_2) { FactoryGirl.create(:lending_limit, lender: original_lender, name: 'B') }
    let!(:new_lending_limit_1) { FactoryGirl.create(:lending_limit, lender: new_lender, name: 'A') }
    let!(:new_lending_limit_2) { FactoryGirl.create(:lending_limit, lender: new_lender, name: 'C') }
    let(:loan_1) { FactoryGirl.create(:loan, lender: original_lender, lending_limit: original_lending_limit_1) }
    let(:loan_2) { FactoryGirl.create(:loan, lender: original_lender, lending_limit: original_lending_limit_1) }
    let(:loan_3) { FactoryGirl.create(:loan, lender: original_lender, lending_limit: original_lending_limit_2) }
    let(:loan_4) { FactoryGirl.create(:loan, lender: original_lender, lending_limit: nil) }
    let(:loans) { [loan_1, loan_2, loan_3, loan_4] }

    before do
      # TODO: Loan factory doesn't allow a nil lending_limit.
      loan_4.update_column(:lending_limit_id, nil)
    end

    context "transferring loans" do
      before { VerdeTransfer.run(loans, new_lender) }

      shared_examples "transferred loan" do
        subject { loan }
        before { loan.reload }

        its(:lender) { should eq(new_lender) }

        context "loan state change" do
          subject { loan.state_changes.last }

          it do
            expect(subject.modified_by).to eq(system_user)
            expect(subject.event).to eq(LoanEvent::EFGTransfer)
            expect(subject.state).to eq(loan.state)
          end
        end
      end

      context "loan 1" do
        let(:loan) { loan_1 }
        it_behaves_like "transferred loan"
      end

      context "loan 2" do
        let(:loan) { loan_2 }
        it_behaves_like "transferred loan"
      end

      context "loan 3" do
        let(:loan) { loan_3 }
        it_behaves_like "transferred loan"
      end

      context "loan 4" do
        let(:loan) { loan_4 }
        it_behaves_like "transferred loan"
      end
    end

    context 'lending limits' do
      before do
        VerdeTransfer.run(loans, new_lender)

        loan_1.reload
        loan_2.reload
        loan_3.reload
        loan_4.reload
      end

      it 'assigns a matching lending limit from the new lender based on name' do
        expect(loan_1.lending_limit).to eq(new_lending_limit_1)
        expect(loan_2.lending_limit).to eq(new_lending_limit_1)
        expect(loan_3.lending_limit).to be_nil
        expect(loan_4.lending_limit).to be_nil
      end
    end
  end
end
