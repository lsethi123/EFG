class ReprofileDrawsLoanChange < LoanChangePresenter
  LoanAlreadyFullyDrawnError = Class.new(StandardError)

  include TrancheDrawdownsFields

  before_save :update_loan_change

  def initialize(loan, _)
    raise LoanAlreadyFullyDrawnError if loan.fully_drawn?
    super
  end

  private
    def update_loan_change
      loan_change.change_type = ChangeType::ReprofileDraws
    end
end
