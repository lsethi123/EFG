class LoanImporter < BaseImporter
  self.csv_path = Rails.root.join('import_data/SFLG_LOAN_DATA_TABLE.csv')
  self.klass = Loan

  def self.extra_columns
    [:created_by_id, :invoice_id, :lender_id, :lending_limit_id,
      :modified_by_id]
  end

  def self.field_mapping
    {
      "OID"                           => :legacy_id,
      "REF"                           => :reference,
      "AMOUNT"                        => :amount,
      "TRADING_DATE"                  => :trading_date,
      "TURNOVER"                      => :turnover,
      "STATUS"                        => :state,
      "CREATED_BY"                    => :created_by_legacy_id,
      "CREATION_TIME"                 => :created_at,
      "LAST_MODIFIED"                 => :updated_at,
      "VERSION"                       => :version,
      "GUARANTEED_DATE"               => :guaranteed_on,
      "MODIFIED_BY"                   => :modified_by_legacy_id,
      "LENDER_OID"                    => :lender_legacy_id,
      "OUTSTANDING_AMOUNT"            => :outstanding_amount,
      "STANDARD_CAP"                  => :standard_cap,
      "BUSINESS_NAME"                 => :business_name,
      "TRADING_NAME"                  => :trading_name,
      "COMPANY_REG"                   => :company_registration,
      "POSTCODE"                      => :postcode,
      "BRANCH_SORTCODE"               => :branch_sortcode,
      "LOAN_TERM"                     => :repayment_duration,
      "CANCEL_COMMENTS"               => :cancelled_comment,
      "NEXT_CHANGE_HISTORY_SEQ"       => :next_change_history_seq,
      "DECLARATION_SIGNED"            => :declaration_signed,
      "BORROWER_DEMAND_DATE"          => :borrower_demanded_on,
      "CANCELLED_DATE"                => :cancelled_on,
      "REPAID_DATE"                   => :repaid_on,
      "VIABLE_PROPOSITION"            => :viable_proposition,
      "COLLATERAL_EXHAUSTED"          => :collateral_exhausted,
      "GENERIC1"                      => :generic1,
      "GENERIC2"                      => :generic2,
      "GENERIC3"                      => :generic3,
      "GENERIC4"                      => :generic4,
      "GENERIC5"                      => :generic5,
      "FACILITY_LETTER_DATE"          => :facility_letter_date,
      "FACILITY_LETTER_SENT"          => :facility_letter_sent,
      "DTI_DEMAND_DATE"               => :dti_demanded_on,
      "DTI_DEMAND_OUTSTANDING"        => :dti_demand_outstanding,
      "BORROWER_DEMAND_OUTSTANDING"   => :borrower_demand_outstanding,
      "REALISED_MONEY_DATE"           => :realised_money_date,
      "NO_CLAIM_DATE"                 => :no_claim_on,
      "EVENT_ID"                      => :event_legacy_id,
      "STATE_AID"                     => :state_aid,
      "PREVIOUS_BORROWING"            => :previous_borrowing,
      "WOULD_YOU_LEND"                => :would_you_lend,
      "AR_TIMESTAMP"                  => :ar_timestamp,
      "AR_INSERT_TIMESTAMP"           => :ar_insert_timestamp,
      "MATURITY_DATE"                 => :maturity_date,
      "FIRST_PP_RECVD"                => :first_pp_received,
      "SIGNED_DD_RECVD"               => :signed_direct_debit_received,
      "RECEIVED_DECLARATION"          => :received_declaration,
      "STATE_AID_IS_VALID"            => :state_aid_is_valid,
      "NOTIFIED_AID"                  => :notified_aid,
      "SIC_SFLG_CODE"                 => :sic_code,
      "REMOVE_GUARANTEE_OUTSTD_AMT"   => :remove_guarantee_outstanding_amount,
      "REMOVE_GUARANTEE_DATE"         => :remove_guarantee_on,
      "REMOVE_GUARANTEE_REASON"       => :remove_guarantee_reason,
      "DTI_AMOUNT_CLAIMED"            => :dti_amount_claimed,
      "INVOICE_OID"                   => :invoice_legacy_id,
      "SETTLEMENT_DATE"               => :settled_on,
      "AMOUNT_DEMANDED"               => :amount_demanded,
      "NEXT_BORROWER_DEMAND_SEQ"      => :next_borrower_demand_seq,
      "SIC_DESC"                      => :sic_desc,
      "SIC_PARENT_DESC"               => :sic_parent_desc,
      "SIC_NOTIFIED_AID"              => :sic_notified_aid,
      "SIC_ELIGIBLE"                  => :sic_eligible,
      "LENDER_CAP_ID"                 => :lender_cap_id,
      "TOWN"                          => :town,
      "NON_VAL_POSTCODE"              => :non_val_postcode,
      "TRANSFERRED_FROM"              => :transferred_from_legacy_id,
      "NEXT_IN_CALC_SEQ"              => :next_in_calc_seq,
      "DTI_REASON_TEXT"               => :dti_reason,
      "LOAN_SOURCE"                   => :loan_source,
      "DTI_BREAK_COSTS"               => :dti_break_costs,
      "GUARANTEE_RATE"                => :guarantee_rate,
      "PREMIUM_RATE"                  => :premium_rate,
      "LEGACY_SMALL_LOAN"             => :legacy_small_loan,
      "NEXT_IN_REALISE_SEQ"           => :next_in_realise_seq,
      "NEXT_IN_RECOVER_SEQ"           => :next_in_recover_seq,
      "RECOVERY_DATE"                 => :recovery_on,
      "RECOVERY_STATEMENT_OID"        => :recovery_statement_legacy_id,
      "DTI_DED_CODE"                  => :dti_ded_code,
      "DTI_INTEREST"                  => :dti_interest,
      "LOAN_SCHEME"                   => :loan_scheme,
      "EFG_INTEREST_TYPE"             => :interest_rate_type_id,
      "EFG_INTEREST_RATE"             => :interest_rate,
      "EFG_FEES"                      => :fees,
      "REASON"                        => :reason_id,
      "BUSINESS_TYPE"                 => :business_type,
      "PAYMENT_PERIOD"                => :payment_period,
      "CANCEL_REASON"                 => :cancelled_reason_id,
      "LOAN_CATEGORY"                 => :loan_category_id,
      "PRIVATE_RES_CHG_REQD"          => :private_residence_charge_required,
      "PERSONAL_GUARANTEE_REQD"       => :personal_guarantee_required,
      "SECURITY_PROPORTION"           => :security_proportion,
      "CURRENT_REFINANCED_VALUE"      => :current_refinanced_amount,
      "FINAL_REFINANCED_VALUE"        => :final_refinanced_amount,
      "ORIG_OVERDRAFT_PROPORTION"     => :original_overdraft_proportion,
      "REFINANCE_SECURITY_PROPORTION" => :refinance_security_proportion,
      "OVERDRAFT_LIMIT"               => :overdraft_limit,
      "OVERDRAFT_MAINTAINED"          => :overdraft_maintained,
      "INVOICE_DISCOUNT_LIMIT"        => :invoice_discount_limit,
      "DEBTOR_BOOK_COVERAGE"          => :debtor_book_coverage,
      "DEBTOR_BOOK_TOPUP"             => :debtor_book_topup
    }
  end

  def self.invoice_id_from_legacy_id(legacy_id)
    @invoice_id_from_legacy_id ||= Hash[Invoice.select('id, legacy_id').map { |invoice|
      [invoice.legacy_id.to_s, invoice.id]
    }]

    @invoice_id_from_legacy_id[legacy_id.to_s]
  end

  def self.lending_limit_id_from_legacy_id(legacy_id)
    @lending_limit_id_from_legacy_id ||= Hash[LendingLimit.select('id, legacy_id').map { |lending_limit|
      [lending_limit.legacy_id.to_s, lending_limit.id]
    }]

    @lending_limit_id_from_legacy_id[legacy_id.to_s]
  end

  DATES = %w(TRADING_DATE GUARANTEED_DATE BORROWER_DEMAND_DATE CANCELLED_DATE
    REPAID_DATE FACILITY_LETTER_DATE DTI_DEMAND_DATE REALISED_MONEY_DATE
    NO_CLAIM_DATE MATURITY_DATE REMOVE_GUARANTEE_DATE SETTLEMENT_DATE
    RECOVERY_DATE)
  MONIES = %w(AMOUNT TURNOVER EFG_FEES OUTSTANDING_AMOUNT DTI_DEMAND_OUTSTANDING BORROWER_DEMAND_OUTSTANDING
    AMOUNT_DEMANDED STATE_AID REMOVE_GUARANTEE_OUTSTD_AMT DTI_AMOUNT_CLAIMED DTI_INTEREST
    OVERDRAFT_LIMIT CURRENT_REFINANCED_VALUE FINAL_REFINANCED_VALUE INVOICE_DISCOUNT_LIMIT DTI_BREAK_COSTS)
  TIMES = %w(CREATION_TIME LAST_MODIFIED AR_TIMESTAMP AR_INSERT_TIMESTAMP)

  def build_attributes
    row.each do |name, value|
      case name
      when 'CREATED_BY'
        attributes[:created_by_id] = self.class.user_id_from_username(value)
      when 'MODIFIED_BY'
        attributes[:modified_by_id] = self.class.user_id_from_username(value)
      when 'INVOICE_OID'
        attributes[:invoice_id] = self.class.invoice_id_from_legacy_id(value) if value.present?
      when "STATUS"
        value = LOAN_STATE_MAPPING[value]
      when "LOAN_TERM"
        value = value.to_i
      when "LENDER_OID"
        if value.present?
          lender_id = self.class.lender_id_from_legacy_id(value.to_i)
          attributes[:lender_id] = lender_id
        end
      when "LENDER_CAP_ID"
        attributes[:lending_limit_id] = self.class.lending_limit_id_from_legacy_id(value) if value.present?
      when "EFG_INTEREST_TYPE"
        # V = variable (id: 1), F = fixed (id: 2)
        value = (value == 'V' ? 1 : 2) if value.present?
      when *DATES
        value = Date.parse(value) unless value.blank?
      when *MONIES
        value = Money.parse(value).cents
      when *TIMES
        value = Time.parse(value) unless value.blank?
      end

      attributes[self.class.field_mapping[name]] = value
    end
  end
end
