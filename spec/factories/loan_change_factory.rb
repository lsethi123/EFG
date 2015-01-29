FactoryGirl.define do
  factory :loan_change do
    loan
    created_by factory: :lender_user
    date_of_change '1/2/12'
    change_type ChangeType::RecordAgreedDraw
    modified_date '3/4/12'
    amount_drawn Money.new(1_000_00)

    trait :capital_repayment_holiday do
      change_type ChangeType::CapitalRepaymentHoliday
    end

    trait :decrease_term do
      change_type ChangeType::DecreaseTerm
    end

    trait :extend_term do
      change_type ChangeType::ExtendTerm
    end

    trait :lender_demand_satisfied do
      change_type ChangeType::LenderDemandSatisfied
    end

    trait :lump_sum_repayment do
      change_type ChangeType::LumpSumRepayment
      lump_sum_repayment Money.new(500_00)
    end

    trait :repayment_frequency do
      change_type ChangeType::RepaymentFrequency
    end

    trait :reprofile_draws do
      change_type ChangeType::ReprofileDraws
    end

    trait :reschedule do
      premium_schedule_attributes { |loan_change|
        FactoryGirl.attributes_for(:rescheduled_premium_schedule, loan: loan_change.loan)
      }
    end

  end
end
