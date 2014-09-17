FactoryGirl.define do
  factory :loan_change_presenter do
    ignore do
      association :loan, factory: [:loan, :guaranteed]
      association :created_by, factory: :lender_user
    end

    date_of_change Date.current
    initial_draw_amount Money.new(10_000_00)

    initialize_with do
      new(loan, created_by)
    end

    factory :capital_repayment_holiday_loan_change, class: CapitalRepaymentHolidayLoanChange do
      initial_capital_repayment_holiday 6
    end

    factory :lump_sum_repayment_loan_change, class: LumpSumRepaymentLoanChange do
      lump_sum_repayment Money.new(1_000_00)
    end

    factory :repayment_duration_loan_change, class: RepaymentDurationLoanChange do
      added_months 3
    end

    factory :reprofile_draws_loan_change, class: ReprofileDrawsLoanChange

    factory :repayment_frequency_loan_change, class: RepaymentFrequencyLoanChange do
      repayment_frequency_id RepaymentFrequency::Annually.id
    end
  end
end
