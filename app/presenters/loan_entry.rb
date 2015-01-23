class LoanEntry
  include LoanPresenter
  include LoanStateTransition
  include SharedLoanValidations

  transition from: [Loan::Eligible, Loan::Incomplete], to: Loan::Completed, event: LoanEvent::Complete

  attribute :lender, read_only: true
  attribute :state_aid_threshold, read_only: true

  attribute :viable_proposition
  attribute :would_you_lend
  attribute :collateral_exhausted
  attribute :not_insolvent
  attribute :sic_code
  attribute :loan_category_id
  attribute :loan_sub_category_id
  attribute :reason_id
  attribute :previous_borrowing
  attribute :private_residence_charge_required
  attribute :personal_guarantee_required
  attribute :lender_reference
  attribute :amount
  attribute :turnover
  attribute :trading_date
  attribute :lending_limit_id
  attribute :repayment_duration
  attribute :declaration_signed
  attribute :business_name
  attribute :trading_name
  attribute :legal_form_id
  attribute :company_registration
  attribute :postcode
  attribute :sortcode
  attribute :repayment_frequency_id
  attribute :generic1
  attribute :generic2
  attribute :generic3
  attribute :generic4
  attribute :generic5
  attribute :interest_rate_type_id
  attribute :interest_rate
  attribute :fees
  attribute :state_aid_is_valid
  attribute :state_aid
  attribute :loan_security_types
  attribute :security_proportion
  attribute :original_overdraft_proportion
  attribute :refinance_security_proportion
  attribute :current_refinanced_amount
  attribute :final_refinanced_amount
  attribute :overdraft_limit
  attribute :overdraft_maintained
  attribute :invoice_discount_limit
  attribute :debtor_book_coverage
  attribute :debtor_book_topup
  attribute :sub_lender

  delegate :calculate_state_aid, :reason, :sic, to: :loan

  validates_presence_of :business_name, :fees, :interest_rate,
    :interest_rate_type_id, :legal_form_id, :repayment_frequency_id
  validates_presence_of :state_aid
  validates_presence_of :company_registration, if: ->(loan_entry) { loan_entry.legal_form_id.present? && LegalForm.company_registration_required?(loan_entry.legal_form_id) }
  validate :postcode_allowed
  validate :state_aid_calculated
  validate :state_aid_within_sic_threshold, if: :state_aid
  validate :repayment_frequency_allowed
  validate :company_turnover_is_allowed, if: :turnover
  validates_acceptance_of :state_aid_is_valid, allow_nil: false, accept: true
  validates_presence_of :sub_lender, if: :sub_lender_required?

  validate do
    errors.add(:declaration_signed, :accepted) unless self.declaration_signed
  end

  validate :validate_eligibility
  validate :category_validations

  def premium_schedule_required_for_state_aid_calculation?
    loan.rules.premium_schedule_required_for_state_aid_calculation?
  end

  def save_as_incomplete
    loan.state = Loan::Incomplete
    loan.save(validate: false)
  end

  def complete?
    loan.state == Loan::Completed
  end

  def total_prepayment
    (debtor_book_coverage || 0) + (debtor_book_topup || 0)
  end

  def sub_lender_required?
    sub_lender_names.present?
  end

  def sub_lender_names
    lender.sub_lenders.map(&:name)
  end

  private

  def category_validations
    validators = LoanCategoryValidators.for_category(loan_category_id)
    validators.each do |validator|
      validator.validate(self)
    end
  end

  def postcode_allowed
    errors.add(:postcode, :invalid) unless postcode.full?
  end

  # Note: state aid must be recalculated if the loan term has changed
  def state_aid_calculated
    errors.add(:state_aid, :recalculate) if self.loan.repayment_duration_changed?
  end

  def validate_eligibility
    loan.rules.loan_entry_validations.each do |validator|
      validator.validate(self)
    end
  end

  def state_aid_within_sic_threshold
    if state_aid > state_aid_threshold
      errors.add(:state_aid, :exceeds_sic_threshold, threshold: state_aid_threshold.format(no_cents: true))
    end
  end
end
