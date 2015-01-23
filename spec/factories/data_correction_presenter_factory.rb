FactoryGirl.define do
  factory :data_correction_presenter do
    ignore do
      association :loan, factory: [:loan, :guaranteed]
      association :created_by, factory: :lender_user
    end

    initialize_with do
      new(loan, created_by)
    end

    factory :business_name_data_correction, class: BusinessNameDataCorrection do
      business_name 'New Business Name'
    end

    factory :company_registration_data_correction, class: CompanyRegistrationDataCorrection do
      company_registration '987654'
    end

    factory :generic_fields_data_correction, class: GenericFieldsDataCorrection do
      generic1 "first"
    end

    factory :trading_name_data_correction, class: TradingNameDataCorrection do
      trading_name 'New Trading Name'
    end

    factory :trading_date_data_correction, class: TradingDateDataCorrection do
      trading_date '10/4/13'
    end

    factory :demanded_amount_data_correction, class: DemandedAmountDataCorrection do
      demanded_amount Money.new(1_500_00)
      demanded_interest Money.new(425_00)
      association :loan, factory: [:loan, :guaranteed, :demanded]
    end

    factory :lender_reference_data_correction, class: LenderReferenceDataCorrection do
      lender_reference 'New Lender Reference'
    end

    factory :postcode_data_correction, class: PostcodeDataCorrection do
      postcode 'EC1A 9PN'
    end

    factory :sortcode_data_correction, class: SortcodeDataCorrection do
      sortcode '123456'
    end

    factory :sub_lender_data_correction, class: SubLenderDataCorrection do
      sub_lender 'ACME sub lender'
    end
  end
end
