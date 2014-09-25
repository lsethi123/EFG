class ReprofileDrawsLoanChange < LoanChangePresenter
  LoanAlreadyFullyDrawnError = Class.new(StandardError)

  include TrancheDrawdownsFields

  before_save :update_loan_change

  def initialize(loan, _)
    raise LoanAlreadyFullyDrawnError unless loan.can_reprofile_draws?
    super
  end

  private
    def update_loan_change
      loan_change.change_type = ChangeType::ReprofileDraws
    end
end
