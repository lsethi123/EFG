class ReprofileDrawsLoanChange < LoanChangePresenter
  LoanAlreadyFullyDrawnError = Class.new(StandardError)

  delegate :second_draw_amount, :second_draw_amount=, to: :premium_schedule
  delegate :second_draw_months, :second_draw_months=, to: :premium_schedule
  delegate :third_draw_amount, :third_draw_amount=, to: :premium_schedule
  delegate :third_draw_months, :third_draw_months=, to: :premium_schedule
  delegate :fourth_draw_amount, :fourth_draw_amount=, to: :premium_schedule
  delegate :fourth_draw_months, :fourth_draw_months=, to: :premium_schedule

  attr_accessible :second_draw_amount, :second_draw_months,
                  :third_draw_amount, :third_draw_months, :fourth_draw_amount,
                  :fourth_draw_months

  before_save :update_loan_change

  def initialize(loan, _)
    raise LoanAlreadyFullyDrawnError if loan.fully_drawn?
    super
  end

  def includes_tranche_drawdown_fields?
    true
  end

  private
    def update_loan_change
      loan_change.change_type = ChangeType::ReprofileDraws
    end
end
