class PremiumScheduleQuarter

  # The amount of interest that the government charges for guaranteeing the loan.
  PREMIUM_RATE = 0.02

  attr_reader :quarter, :total_quarters, :premium_schedule, :initial_capital_repayment_holiday

  delegate :initial_draw_amount, to: :premium_schedule
  delegate :initial_draw_months, to: :premium_schedule
  delegate :repayment_duration, to: :premium_schedule
  delegate :second_draw_amount, to: :premium_schedule
  delegate :second_draw_months, to: :premium_schedule
  delegate :third_draw_amount, to: :premium_schedule
  delegate :third_draw_months, to: :premium_schedule
  delegate :fourth_draw_amount, to: :premium_schedule
  delegate :fourth_draw_months, to: :premium_schedule

  def initialize(quarter, total_quarters, premium_schedule)
    @quarter                           = quarter
    @total_quarters                    = total_quarters
    @premium_schedule                  = premium_schedule
    @initial_capital_repayment_holiday = premium_schedule.initial_capital_repayment_holiday.to_i
  end

  def premium_amount
    if quarter < total_quarters
      aggregate_outstanding_amount * (PREMIUM_RATE / 4)
    else
      Money.new(0)
    end
  end

  private

  def aggregate_outstanding_amount
    first_draw_down_outstanding_balance(initial_draw_amount) +
      tranche_drawdown(:second) + tranche_drawdown(:third) + tranche_drawdown(:fourth)
  end

  # return the outstanding amount on the specified tranche draw down
  # if it has come into effect in this, or a previous, quarter
  def tranche_drawdown(tranche_number)
    draw_amount = send("#{tranche_number}_draw_amount")
    draw_month = send("#{tranche_number}_draw_months")

    # draw down doesn't exist
    return Money.new(0) unless draw_amount && draw_month

    months_from_first_draw_until_repayment = get_months_from_first_draw_until_repayment(draw_month)
    remaining_months = initial_draw_months - months_from_first_draw_until_repayment

    if months_from_first_draw_until_repayment <= last_month_in_quarter
      draw_amount - (draw_amount * (last_month_in_quarter - months_from_first_draw_until_repayment)) / remaining_months
    elsif draw_month <= last_month_in_quarter
      draw_amount
    else
      Money.new(0)
    end
  end

  def get_months_from_first_draw_until_repayment(draw_month)
    initial_capital_repayment_holiday <= draw_month ?  draw_month : initial_capital_repayment_holiday
  end

  # how much capital remains on the initial draw amount
  def first_draw_down_outstanding_balance(initial_draw_amount)
    # repayment holiday is complete, either in this or a previous quarter (may have ended mid-quarter e.g. month 5)
    if repayment_holiday_complete?
      remaining_months = initial_draw_months - initial_capital_repayment_holiday
      initial_draw_amount - (initial_draw_amount * (last_month_in_quarter - initial_capital_repayment_holiday)) / remaining_months
    else
      # if in repayment holiday, no capital repaid yet
      if repayment_holiday_active?
        initial_draw_amount
      # some capital already repaid (unless first quarter)
      else
        initial_draw_amount - capital_repaid_to_date
      end
    end
  end

  def last_month_in_quarter
    3 * quarter
  end

  def capital_repaid_to_date
    (initial_draw_amount / total_quarters) * quarter
  end

  def repayment_holiday_complete?
    initial_capital_repayment_holiday < last_month_in_quarter
  end

  def repayment_holiday_active?
    initial_capital_repayment_holiday >= last_month_in_quarter
  end

end
