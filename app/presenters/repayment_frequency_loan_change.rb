class RepaymentFrequencyLoanChange < LoanChangePresenter
  include CapitalRepyamentHolidayFields
  include TrancheDrawdownsFields

  ValidRepaymentFrequencies = [
    RepaymentFrequency::Annually,
    RepaymentFrequency::SixMonthly,
    RepaymentFrequency::Quarterly,
    RepaymentFrequency::Monthly,
    RepaymentFrequency::InterestOnly,
  ]

  attr_accessible :repayment_frequency_id
  attr_reader :repayment_frequency_id

  validates_inclusion_of :repayment_frequency_id, in: ValidRepaymentFrequencies.map(&:id)
  validate :changed_repayment_frequency

  before_save :update_repayment_frequency_ids

  def repayment_frequency_id=(id)
    @repayment_frequency_id = id.blank? ? nil : id.to_i
  end

  private

  def changed_repayment_frequency
    if loan.repayment_frequency_id == repayment_frequency_id
      errors.add(:repayment_frequency_id, :must_be_changed)
    end
  end

  def update_repayment_frequency_ids
    loan_change.change_type = ChangeType::RepaymentFrequency
    loan_change.repayment_frequency_id = repayment_frequency_id
    loan_change.old_repayment_frequency_id = loan.repayment_frequency_id

    loan.repayment_frequency_id = repayment_frequency_id
  end
end
