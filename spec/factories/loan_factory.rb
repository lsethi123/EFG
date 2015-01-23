FactoryGirl.define do
  factory :loan do
    state Loan::Eligible
    lender
    association :created_by, factory: :lender_user
    association :modified_by, factory: :lender_user
    modified_by_legacy_id 'system'
    legal_form_id 1
    loan_category_id LoanCategory::TypeA.id
    repayment_frequency_id 4
    reason_id 28
    business_name 'Acme'
    trading_name 'Emca'
    postcode "EC1R 4RP"
    viable_proposition true
    would_you_lend true
    collateral_exhausted true
    not_insolvent true
    amount 12345
    repayment_duration 24
    turnover 12345
    trading_date 2.years.ago
    sic_code { |loan| FactoryGirl.create(:sic_code).code }
    sic_desc 'Growing of rice'
    sic_eligible true
    previous_borrowing true
    private_residence_charge_required false
    personal_guarantee_required false
    fees 50000
    sequence(:legacy_id) { |n| n }
    created_at { Time.now }
    updated_at { Time.now }
    loan_source Loan::SFLG_SOURCE
    loan_scheme Loan::EFG_SCHEME
    last_modified_at { 1.day.ago }

    after :build do |loan|
      loan.lending_limit ||= FactoryGirl.create(:lending_limit, lender: loan.lender)
    end

    trait :eligible do
      state Loan::Eligible
    end

    trait :rejected do
      state Loan::Rejected

      after(:create) do |loan|
        loan.ineligibility_reasons.create(reason: "Loan amount exceeds allowed limits")
      end
    end

    trait :cancelled do
      state Loan::Cancelled
      cancelled_reason_id 1
      cancelled_comment 'Comment'
      cancelled_on { Date.current }
    end

    trait :completed do
      state Loan::Completed
      state_aid Money.new(10_000_00, 'EUR')
      state_aid_is_valid true
    end

    trait :complete_legacy do
      state Loan::CompleteLegacy
    end

    trait :incomplete do
      state Loan::Incomplete
    end

    trait :offered do
      state Loan::Offered
      facility_letter_sent true
      facility_letter_date { Date.current }
    end

    trait :guaranteed do
      state Loan::Guaranteed
      received_declaration true
      signed_direct_debit_received true
      first_pp_received true
      maturity_date { 10.years.from_now }

      after :create do |loan|
        FactoryGirl.create(:initial_draw_change,
          amount_drawn: Money.new(10_000_00),
          loan: loan
        )
      end
    end

    trait :loan_with_generic_info do
      generic1 "first generic field"
      generic2 "more info in second field"
      generic3 "nowhere else to put this"
      generic4 "entered by ..."
      generic5 "authorized"
    end

    trait :loan_without_generic_info do
      generic1 nil
      generic2 nil
      generic3 nil
      generic4 nil
      generic5 nil
    end

    trait :removed do
      state Loan::Removed
      remove_guarantee_outstanding_amount Money.new(10_000_00)
      remove_guarantee_on { Date.current }
      remove_guarantee_reason 'reason'
    end

    trait :repaid do
      state Loan::Repaid
      repaid_on { Date.current }
    end

    trait :demanded do
      state Loan::Demanded
      dti_demand_outstanding Money.new(10_000_00)
      dti_amount_claimed { |loan| loan.dti_demand_outstanding * 0.75 }
      dti_demanded_on { Date.current }
      dti_reason 'reason'
      ded_code
    end

    trait :not_demanded do
      state Loan::NotDemanded
      no_claim_on { Date.current }
    end

    trait :lender_demand do
      state Loan::LenderDemand
      amount_demanded Money.new(10_000_00)
      borrower_demanded_on Date.new(2012, 6, 1)
    end

    trait :settled do
      state Loan::Settled
      dti_demand_outstanding { |loan| loan.amount * 0.25 }
      dti_amount_claimed { |loan| loan.dti_demand_outstanding * 0.75 }
      settled_amount { |loan| loan.dti_amount_claimed }
      settled_on { Date.current }

      after(:create) do |loan|
        loan.invoice = FactoryGirl.create(:invoice)
      end
    end

    trait :recovered do
      state Loan::Recovered
      recovery_on { Date.current }
    end

    trait :realised do
      state Loan::Realised
      realised_money_date { Date.current }
    end

    trait :repaid_from_transfer do
      state Loan::RepaidFromTransfer
    end

    trait :auto_removed do
      state Loan::AutoRemoved
    end

    trait :auto_cancelled do
      state Loan::AutoCancelled
    end

    trait :transferred do
      reference 'ABCDEFG+02'
      state Loan::Incomplete

      after :create do |loan|
        FactoryGirl.create(:initial_draw_change,
          amount_drawn: Money.new(10_000_00),
          loan: loan
        )
      end
    end

    trait :with_premium_schedule do
      after(:build) do |loan|
        loan.premium_schedules = [ FactoryGirl.build(:premium_schedule) ]
      end
    end

    trait :with_loan_securities do
      after(:build) do |loan|
        loan.loan_security_types = [ 1, 2 ]
      end
    end

    trait :with_sub_lender do
      sub_lender "ACME sub-lender"
    end

    trait :efg do
      loan_scheme Loan::EFG_SCHEME
      loan_source Loan::SFLG_SOURCE
    end

    trait :sflg do
      sequence(:reference) { |num| "ABC" + ("%04d" % num) + "-01"  } # e.g. ABC0004-01
      loan_source Loan::SFLG_SOURCE
      loan_scheme Loan::SFLG_SCHEME
    end

    trait :legacy_sflg do
      sequence(:reference) { |num| "%06d" % num } # e.g. 000005
      loan_source Loan::LEGACY_SFLG_SOURCE
      loan_scheme Loan::SFLG_SCHEME
    end
  end
end
