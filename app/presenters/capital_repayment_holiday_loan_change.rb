class CapitalRepaymentHolidayLoanChange < LoanChangePresenter
  validate :validate_capital_repayment_holiday
  before_save :update_loan_change

  private
    def update_loan_change
      loan_change.change_type = ChangeType::CapitalRepaymentHoliday
    end

    def validate_capital_repayment_holiday
      if initial_capital_repayment_holiday.nil?
        errors.add(:initial_capital_repayment_holiday, :required)
      elsif initial_capital_repayment_holiday <= 0
        errors.add(:initial_capital_repayment_holiday, :must_be_gt_zero)
      end
    end
end
