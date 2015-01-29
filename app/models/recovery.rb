class Recovery < ActiveRecord::Base
  include FormatterConcern
  include Sequenceable

  belongs_to :loan
  belongs_to :created_by, class_name: 'User'
  belongs_to :realisation_statement

  scope :realised, -> { where(realise_flag: true) }

  validates_presence_of :loan, strict: true
  validates_presence_of :created_by, strict: true
  validates_presence_of :recovered_on

  validate :validate_scheme_fields
  validate do
    if loan && recovered_on && recovered_on < loan.settled_on
      errors.add(:recovered_on, 'must not be before the loan was settled')
    end
  end

  format :recovered_on, with: QuickDateFormatter
  format :outstanding_non_efg_debt, with: MoneyFormatter.new
  format :non_linked_security_proceeds, with: MoneyFormatter.new
  format :linked_security_proceeds, with: MoneyFormatter.new
  format :realisations_attributable, with: MoneyFormatter.new
  format :amount_due_to_dti, with: MoneyFormatter.new
  format :total_proceeds_recovered, with: MoneyFormatter.new
  format :total_liabilities_after_demand, with: MoneyFormatter.new
  format :total_liabilities_behind, with: MoneyFormatter.new
  format :additional_break_costs, with: MoneyFormatter.new
  format :additional_interest_accrued, with: MoneyFormatter.new
  format :realisations_due_to_gov, with: MoneyFormatter.new

  attr_accessible :recovered_on, :outstanding_non_efg_debt,
    :non_linked_security_proceeds, :linked_security_proceeds,
    :total_liabilities_behind, :total_liabilities_after_demand,
    :additional_interest_accrued, :additional_break_costs

  attr_accessor :amount_due_to_sec_state

  def calculate
    loan_guarantee_rate = loan.guarantee_rate / 100

    if loan.efg_loan?
      # See Visio document page 34.
      self.realisations_attributable = [
        non_linked_security_proceeds + linked_security_proceeds - outstanding_non_efg_debt,
        Money.new(0)
      ].max

      self.amount_due_to_dti = realisations_attributable * loan_guarantee_rate
    else
      self.additional_break_costs ||= Money.new(0)
      self.additional_interest_accrued ||= Money.new(0)

      magic_number = if loan.legacy_loan?
        another_magic_number = loan.dti_amount_claimed / loan_guarantee_rate
        another_magic_number / (another_magic_number + total_liabilities_behind)
      else
        interest_plus_outstanding = loan.dti_interest + loan.dti_demand_outstanding
        interest_plus_outstanding / (interest_plus_outstanding + total_liabilities_behind)
      end

      self.amount_due_to_sec_state = total_liabilities_after_demand * loan_guarantee_rate * magic_number
      self.amount_due_to_dti = amount_due_to_sec_state + additional_break_costs + additional_interest_accrued
    end

    amount_yet_to_be_recovered = loan.dti_amount_claimed - loan.cumulative_recoveries_amount
    if (self.amount_due_to_dti > amount_yet_to_be_recovered)
      errors.add(:base, :recovery_too_high)
    end

    self.amount_due_to_dti
  end

  def save_and_update_loan
    transaction do
      save!
      update_loan!
      log_loan_state_change!
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def set_total_proceeds_recovered
    if loan.legacy_loan?
      self.total_proceeds_recovered = loan.dti_amount_claimed * (loan.guarantee_rate / 100)
    else
      interest = loan.dti_interest || Money.new(0)
      outstanding = loan.dti_demand_outstanding || Money.new(0)

      self.total_proceeds_recovered = interest + outstanding
    end
  end

  private
    def update_loan!
      loan.modified_by = created_by
      loan.recovery_on = recovered_on
      loan.state = Loan::Recovered
      loan.save!
    end

    def log_loan_state_change!
      LoanStateChange.log(loan, LoanEvent::RecoveryMade, created_by)
    end

    def validate_scheme_fields
      required = if loan.efg_loan?
        [:linked_security_proceeds, :outstanding_non_efg_debt,
          :non_linked_security_proceeds]
      else
        [:total_liabilities_behind, :total_liabilities_after_demand]
      end

      required.each do |attribute|
        errors.add(attribute, :blank) if self[attribute].blank?
      end
    end
end
