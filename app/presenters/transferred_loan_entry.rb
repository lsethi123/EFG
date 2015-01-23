class TransferredLoanEntry
  include LoanPresenter
  include LoanStateTransition
  include SharedLoanValidations

  transition from: [Loan::Incomplete], to: Loan::Completed, event: LoanEvent::Complete

  attribute :viable_proposition, read_only: true
  attribute :would_you_lend, read_only: true
  attribute :collateral_exhausted, read_only: true
  attribute :sic_code, read_only: true
  attribute :reason_id, read_only: true
  attribute :private_residence_charge_required, read_only: true
  attribute :personal_guarantee_required, read_only: true
  attribute :turnover, read_only: true
  attribute :trading_date, read_only: true
  attribute :lender, read_only: true
  attribute :reference, read_only: true
  attribute :business_name, read_only: true
  attribute :trading_name, read_only: true
  attribute :legal_form_id, read_only: true
  attribute :company_registration, read_only: true
  attribute :postcode, read_only: true
  attribute :legacy_loan?, read_only: true
  attribute :state_aid_is_valid, read_only: true
  attribute :premium_rate, read_only: true
  attribute :guarantee_rate, read_only: true

  attribute :declaration_signed
  attribute :sortcode
  attribute :lender_reference
  attribute :amount
  attribute :repayment_duration
  attribute :repayment_frequency_id
  attribute :state_aid
  attribute :sub_lender
  attribute :generic1
  attribute :generic2
  attribute :generic3
  attribute :generic4
  attribute :generic5

  delegate :sub_lender_names, to: :lender

  validates_presence_of :amount, :repayment_duration, :repayment_frequency_id
  validates_inclusion_of :sub_lender, in: :sub_lender_names, if: -> { sub_lender_names.present? }
  validate :repayment_frequency_allowed

  validate do
    errors.add(:declaration_signed, :accepted) unless self.declaration_signed
    errors.add(:state_aid, :calculated) unless self.loan.premium_schedule
  end

  def initialize(loan)
    super
    raise ArgumentError, 'loan is not a transferred loan' unless @loan.created_from_transfer?
  end

  def save_as_incomplete
    loan.state = Loan::Incomplete
    loan.save(validate: false)
  end
end
