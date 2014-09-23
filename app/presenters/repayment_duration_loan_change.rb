class RepaymentDurationLoanChange < LoanChangePresenter
  include CapitalRepyamentHolidayFields
  include TrancheDrawdownsFields

  attr_reader :added_months, :repayment_duration
  attr_accessible :added_months

  validate :validate_added_months
  validate :phase_validations

  before_save :update_loan_change
  before_save :update_loan

  def added_months=(value)
    @added_months = value.present? ? value.to_i : nil

    if added_months
      @repayment_duration = MonthDuration.new(loan.repayment_duration.total_months + added_months)
    end
  end

  private
    delegate :amount, to: :loan

    def months_per_repayment_period
      loan.repayment_frequency.try(:months_per_repayment_period) || 1
    end

    def maturity_date
      initial_draw_date = loan.initial_draw_change.date_of_change
      initial_draw_date.advance(months: repayment_duration.total_months)
    end

    def phase_validations
      loan.rules.repayment_duration_loan_change_validations.each do |validator|
        validator.validate(self)
      end
    end

    def update_loan
      loan.repayment_duration = repayment_duration.total_months
      loan.maturity_date = maturity_date
    end

    def update_loan_change
      loan_change.change_type = added_months > 0 ? ChangeType::ExtendTerm : ChangeType::DecreaseTerm
      loan_change.repayment_duration = repayment_duration.total_months
      loan_change.old_repayment_duration = loan.repayment_duration.total_months
      loan_change.maturity_date = maturity_date
      loan_change.old_maturity_date = loan.maturity_date
    end

    def repayment_duration_at_next_premium
      months = super
      months += added_months if added_months
      months
    end

    def validate_added_months
      if added_months.nil?
        errors.add(:added_months, :required)
      elsif added_months.zero?
        errors.add(:added_months, :must_not_be_zero)
      elsif added_months % months_per_repayment_period != 0
        errors.add(:added_months, :must_match_repayment_frequency, months_per_repayment_period: months_per_repayment_period)
      elsif repayment_duration_at_next_premium <= 0
        errors.add(:added_months, :must_have_a_positive_repayment_duration_at_next_premium)
      end
    end
end
