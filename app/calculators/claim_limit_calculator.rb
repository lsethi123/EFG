class ClaimLimitCalculator

  ClaimLimitStates = [
    Loan::Guaranteed,
    Loan::LenderDemand,
    Loan::Repaid,
    Loan::RepaidFromTransfer,
    Loan::NotDemanded,
    Loan::Demanded,
    Loan::Settled,
    Loan::Realised,
    Loan::Recovered,
    Loan::AutoRemoved,
    Loan::Removed,
  ].freeze

  SettledStates = [
    Loan::Settled,
    Loan::Realised,
    Loan::Recovered,
  ].freeze

  ChangeTypesWithDraws = [
    ChangeType::CapitalRepaymentHoliday,
    ChangeType::DecreaseTerm,
    ChangeType::ExtendTerm,
    ChangeType::LumpSumRepayment,
    ChangeType::RecordAgreedDraw,
    ChangeType::ReprofileDraws,
    ChangeType::RepaymentFrequency
  ].freeze

  attr_reader :lender

  def initialize(lender)
    @lender = lender
  end

  def self.all_with_amount(lenders)
    lenders.each_with_object([]) do |lender, memo|
      Phase.all.each do |phase|
        calculator = phase.rules.claim_limit_calculator.new(lender)
        memo << calculator unless calculator.total_amount.zero?
      end
    end
  end

  def amount_remaining
    remainder = total_amount + pre_claim_realisations_amount - settled_amount
    remainder < 0 ? Money.new(0) : remainder
  end

  def cumulative_drawn_amount
    @cumulative_drawn_amount ||= begin
      amount = cumulative_drawn_amount_relation.sum(:amount_drawn)
      Money.new(amount)
    end
  end

  def percentage_remaining
    return 0 if total_amount.zero?
    return 100 if amount_remaining.zero?

    (amount_remaining / total_amount * 100).round
  end

  def phase
    raise NotImplementedError, 'Implement in sub-class'
  end

  def pre_claim_realisations_amount
    @pre_claim_realisations_amount ||= begin
      pre_claim_realisations_amount = Loan
        .joins(:loan_realisations)
        .joins(:lending_limit)
        .where(lender_id: lender.id)
        .where(loan_scheme: Loan::EFG_SCHEME)
        .where(state: SettledStates)
        .where(lending_limits: { phase_id: phase.id })
        .where(loan_realisations: { post_claim_limit: false })
        .sum(:realised_amount)

      realisation_adjustments_amount = lender.realisation_adjustments.sum(:amount)

      Money.new(pre_claim_realisations_amount) - Money.new(realisation_adjustments_amount)
    end
  end

  def settled_amount
    @settled_amount ||= begin
      amount = Loan
        .joins(:lending_limit)
        .where(lender_id: lender.id)
        .where(loan_scheme: Loan::EFG_SCHEME)
        .where(state: SettledStates)
        .where(lending_limits: { phase_id: phase.id})
        .sum(:settled_amount)

      Money.new(amount)
    end
  end

  def total_amount
    raise NotImplementedError, 'Implement in sub-class'
  end

  private

  def cumulative_drawn_amount_relation
    Loan
      .joins(:loan_modifications)
      .joins(:lending_limit)
      .where(lender_id: lender.id)
      .where(loan_scheme: Loan::EFG_SCHEME)
      .where(state: ClaimLimitStates)
      .where("loan_modifications.type = 'InitialDrawChange' OR
              loan_modifications.change_type_id IN (?)",
              ChangeTypesWithDraws.collect(&:id))
      .where(lending_limits: { phase_id: phase.id })
  end

end
