module LoanChangeSpecHelper
  extend ActiveSupport::Concern

  included do
    let(:loan) {
      FactoryGirl.create(:loan, :guaranteed, :with_premium_schedule, {
        amount: Money.new(100_000_00),
        maturity_date: Date.new(2014, 12, 25),
        repayment_duration: 60,
        repayment_frequency_id: RepaymentFrequency::Quarterly.id
      })
    }

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
