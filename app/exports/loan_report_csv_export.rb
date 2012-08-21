class LoanReportCsvExport

  def initialize(loans_scope)
    @loans_scope = loans_scope
    unless loans_scope.is_a?(ActiveRecord::Relation)
      raise ArgumentError, "Expected loans_scope to be instance of ActiveRecord::Relation"
    end
  end

  def header
    %w(
      loan_reference
      legal_form
      post_code
      non_validated_post_code
      town
      annual_turnover
      trading_date
      sic_code
      sic_code_description
      parent_sic_code_description
      purpose_of_loan
      facility_amount
      guarantee_rate
      premium_rate
      lending_limit
      lender_reference
      loan_state
      loan_term
      repayment_frequency
      maturity_date
      generic1
      generic2
      generic3
      generic4
      generic5
      cancellation_reason
      cancellation_comment
      cancellation_date
      scheme_facility_letter_date
      initial_draw_amount
      initial_draw_date
      lender_demand_date
      lender_demand_amount
      repaid_date
      no_claim_date
      demand_made_date
      outstanding_facility_principal
      total_claimed
      outstanding_facility_interest
      business_failure_group
      business_failure_category_description
      business_failure_description
      business_failure_code
      government_demand_reason
      break_cost
      latest_recovery_date
      total_recovered
      latest_realised_date
      total_realised
      cumulative_amount_drawn
      total_lump_sum_repayments
      created_by
      created_at
      modified_by
      modified_date
      guarantee_remove_date
      outstanding_balance
      guarantee_remove_reason
      state_aid_amount
      settled_date
      invoice_reference
      loan_category
      interest_type
      interest_rate
      fees
      type_a1
      type_a2
      type_b1
      type_d1
      type_d2
      type_c1
      security_type
      type_c_d1
      type_e1
      type_e2
      type_f1
      type_f2
      type_f3
    ).collect { |field| t(field) }
  end

  def generate
    CSV.generate do |csv|
      csv << header
      @loans_scope.find_each do |loan|
        csv << LoanReportCsvRow.new(loan).row
      end
    end
  end

  private

  def t(key)
    I18n.t(key, scope: 'csv_headers.loan_report')
  end

end