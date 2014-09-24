module LoanChangeSpecHelper
  extend ActiveSupport::Concern

  included do
    let(:current_user) { FactoryGirl.create(:lender_user, lender: loan.lender) }
    before { login_as(current_user, scope: :user) }
  end

  private
    def fill_in(attribute, value)
      page.fill_in "loan_change_#{attribute}", with: value
    end

    def select(attribute, value)
      page.select value, from: "loan_change_#{attribute}"
    end
end
