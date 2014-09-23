class ReprofileDrawsLoanChange < LoanChangePresenter
  include CapitalRepyamentHolidayFields
  include TrancheDrawdownsFields

  before_save :update_loan_change

  private
    def update_loan_change
      loan_change.change_type = ChangeType::ReprofileDraws
    end
end
