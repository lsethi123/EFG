require 'spec_helper'
require 'csv'

describe LoanReportPresenter do

  describe "#initialize" do
    let(:lender) { double(Lender, id: 89) }
    let(:user) { double('user', lender: lender, lender_ids: [lender.id]) }

    it "should not allow unsupported attributes" do
      expect {
        LoanReportPresenter.new(user, report_attributes(company_registration: '123456C'))
      }.to raise_error(NoMethodError)
    end
  end

  describe "validation" do
    let(:user) { FactoryGirl.create(:lender_user) }
    let(:loan_report_presenter) { LoanReportPresenter.new(user, report_attributes) }

    it 'should have a valid factory' do
      expect(loan_report_presenter).to be_valid
    end

    it 'should be invalid without an allowed loan state' do
      loan_report_presenter.states = [ "wrong" ]
      expect(loan_report_presenter).not_to be_valid

      loan_report_presenter.states = [ Loan::Guaranteed ]
      expect(loan_report_presenter).to be_valid
    end

    it 'should be invalid without numeric created by user ID' do
      loan_report_presenter.created_by_id = 'a'
      expect(loan_report_presenter).not_to be_valid
    end

    it 'should be valid with blank created by user ID' do
      loan_report_presenter.created_by_id = ''
      expect(loan_report_presenter).to be_valid
    end

    it 'should be invalid without a loan type' do
      loan_report_presenter.loan_types = nil
      expect(loan_report_presenter).not_to be_valid

      loan_report_presenter.loan_types = []
      expect(loan_report_presenter).not_to be_valid
    end

    it 'should be invalid without a valid loan type' do
      loan_report_presenter.loan_types = ["Z"]
      expect(loan_report_presenter).not_to be_valid

      loan_report_presenter.loan_types = [LoanTypes::LEGACY_SFLG.id]
      expect(loan_report_presenter).to be_valid
    end

    it 'should be invalid without lender IDs' do
      user = FactoryGirl.create(:cfe_user)
      loan_report_presenter = LoanReportPresenter.new(user, report_attributes)

      loan_report_presenter.lender_ids = nil
      expect(loan_report_presenter).not_to be_valid
    end

    it 'should be invalid without a numeric created by ID' do
      loan_report_presenter.created_by_id = 'a'
      expect(loan_report_presenter).not_to be_valid
    end
  end

  describe "delegating to report" do
    let(:user) { FactoryGirl.create(:lender_user) }
    let(:loan_report) { double('LoanReport') }
    let(:presenter) { LoanReportPresenter.new(user) }
    before { allow(presenter).to receive(:report).and_return(loan_report) }

    it "delegates #count" do
      expect(loan_report).to receive(:count).and_return(45)
      expect(presenter.count).to eq(45)
    end

    it "delgates #loans" do
      loans = double('loans')
      expect(loan_report).to receive(:loans).and_return(loans)
      expect(presenter.loans).to eq(loans)
    end
  end

  describe "permissions" do
    let(:presenter) { LoanReportPresenter.new(user) }

    context "with AuditorUser" do
      let(:user) { FactoryGirl.build(:auditor_user) }

      it "allows lender selection" do
        expect(presenter).to have_lender_selection
      end

      it "doesn't allow created by selection" do
        expect(presenter).not_to have_created_by_selection
      end
    end

    context "with CfeUser" do
      let(:user) { FactoryGirl.build(:cfe_user) }

      it "allows lender selection" do
        expect(presenter).to have_lender_selection
      end

      it "allows loan type selection" do
        expect(presenter).to have_loan_type_selection
      end

      it "doesn't allow created by selection" do
        expect(presenter).not_to have_created_by_selection
      end
    end

    context "with LenderUser" do
      let(:user) { FactoryGirl.build(:lender_user) }

      it "doesn't allow lender selection" do
        expect(presenter).not_to have_lender_selection
      end

      it "allows created by selection" do
        expect(presenter).to have_created_by_selection
      end
    end

    context "with a users's 'lender' that can access all loan schemes" do
      let(:lender) { double('lender', :can_access_all_loan_schemes? => true)}
      let(:user) { FactoryGirl.build(:lender_user) }
      before { allow(user).to receive(:lender).and_return(lender) }

      it "allows loan type selection" do
        expect(presenter).to have_loan_type_selection
      end
    end

    context "with a user's 'lender' that can't access all loan schemes" do
      let(:lender) { double('lender', :can_access_all_loan_schemes? => false)}
      let(:user) { FactoryGirl.build(:lender_user) }
      before { allow(user).to receive(:lender).and_return(lender) }

      it "doesn't allow loan type selection" do
        expect(presenter).not_to have_loan_type_selection
      end
    end
  end

  describe "#report" do
    let(:presenter) { LoanReportPresenter.new(user, report_attributes) }

    context "with a LenderUser" do
      let(:lender) { FactoryGirl.create(:lender) }
      let(:user) { FactoryGirl.create(:lender_user, lender: lender) }

      it "sets the report's lender_ids the user's lender_id" do
        expect(presenter.report.lender_ids).to eq([lender.id])
      end
    end

    context "with a user who can select lenders" do
      let!(:lender1) { FactoryGirl.create(:lender) }
      let!(:lender2) { FactoryGirl.create(:lender) }
      let!(:lender3) { FactoryGirl.create(:lender) }
      let(:user) { FactoryGirl.build(:cfe_user) }

      it "sets lender_ids to the selected lender_ids" do
        presenter.lender_ids = [lender1.id, lender3.id]
        expect(presenter.report.lender_ids).to eq([lender1.id, lender3.id])
      end

      it "removes any lender_ids that the user can't access" do
        allow(user).to receive(:lender_ids).and_return([lender1.id, lender2.id])

        presenter.lender_ids = [lender1.id, lender3.id]
        expect(presenter.report.lender_ids).to eq([lender1.id])
      end
    end

    context "with a user who can access all loan schemes" do
      let(:lender) { FactoryGirl.create(:lender, loan_scheme: '') }
      let(:user) { FactoryGirl.create(:lender_user, lender: lender) }
      let(:presenter) { LoanReportPresenter.new(user) }

      it "doesn't set loan_types" do
        expect(presenter.loan_types).to be_nil
      end
    end

    context "with a user who can't access all loan schemes" do
      let(:lender) { FactoryGirl.create(:lender, loan_scheme: 'E') }
      let(:user) { FactoryGirl.create(:lender_user, lender: lender) }
      let(:presenter) { LoanReportPresenter.new(user) }

      it "sets the loan_types to EFG" do
        expect(presenter.loan_types).to eq([LoanTypes::EFG])
      end
    end
  end

  private

  def report_attributes(params = {})
    lender_ids = Lender.count.zero? ? [ 1 ] : Lender.all.collect(&:id)

    {
      lender_ids: lender_ids,
      loan_types: [LoanTypes::NEW_SFLG.id, LoanTypes::EFG.id],
      states: Loan::States,
    }.merge(params)
  end

end
