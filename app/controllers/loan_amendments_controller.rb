class LoanAmendmentsController < ApplicationController
  before_filter :verify_view_permission
  before_filter :load_loan

  def index
    @loan_amendments = LoanAmendmentPresenter.for_loan(@loan)
  end

  def show
    @loan_amendment = LoanAmendmentPresenter.new(@loan, params)
  end

  private
    def load_loan
      @loan = current_lender.loans.find(params[:loan_id])
    end

    def verify_view_permission
      enforce_view_permission(LoanModification)
    end
end
