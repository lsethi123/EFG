require 'spec_helper'

describe ClaimLimitsReportsController do

  describe "GET show" do
    def dispatch
      get :show, format: :csv
    end

    it_behaves_like 'AuditorUser-restricted controller'
    it_behaves_like 'CfeAdmin-restricted controller'
    it_behaves_like 'LenderAdmin-restricted controller'
    it_behaves_like 'LenderUser-restricted controller'
    it_behaves_like 'PremiumCollectorUser-restricted controller'

    context 'when Cfe User' do
      let(:current_user) { FactoryGirl.create(:cfe_user) }

      before do
        sign_in(current_user)
      end

      context do
        before do
          dispatch
        end

        it "renders CSV loan data" do
          expect(response.content_type).to eq('text/csv')
        end

        it "sets filename for CSV" do
          expected_filename = "lender_claim_limits_#{Date.current.strftime('%Y-%m-%d')}.csv"
          expect(response.headers['Content-Disposition']).to include(%Q(filename="#{expected_filename}"))
        end
      end

      context "with active and inactive lenders" do
        let!(:active_lender) { FactoryGirl.create(:lender) }
        let!(:inactive_lender) { FactoryGirl.create(:lender, :disabled) }

        it "includes all lenders in report" do
          expect(ClaimLimitCalculator).to receive(:all_with_amount).with([active_lender, inactive_lender])
          dispatch
        end
      end
    end
  end

end
