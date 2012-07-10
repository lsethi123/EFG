class RealisationStatement < ActiveRecord::Base
  include FormatterConcern

  PERIOD_COVERED_QUARTERS = ['March', 'June', 'September', 'December']

  belongs_to :lender
  belongs_to :created_by, class_name: 'User'
  has_many :loan_realisations
  has_many :realised_loans, through: :loan_realisations

  validates :lender_id, presence: true
  validates :created_by_id, presence: true, on: :create
  validates :reference, presence: true
  validates :period_covered_quarter, presence: true, inclusion: PERIOD_COVERED_QUARTERS
  validates :period_covered_year, presence: true, format: /\A(\d{4})\Z/
  validates :received_on, presence: true

  format :received_on, with: QuickDateFormatter

  attr_accessible :lender_id, :reference, :period_covered_quarter,
                  :period_covered_year, :received_on

  def recovered_loans
    lender.loans.recovered
  end

  def loans_to_be_realised
    @loans_to_be_realised || []
  end

  def loans_to_be_realised_ids=(ids)
    @loans_to_be_realised = Loan.where(id: ids)
  end

  after_save :transition_loans
  def transition_loans
    raise LoanStateTransition::IncorrectLoanState unless loans_to_be_realised.all? {|loan| loan.state == Loan::Recovered }
    loans_to_be_realised.update_all(state: Loan::Realised)
    # TODO: persist realised amount in LoanRealisation
    self.realised_loans = loans_to_be_realised
  end

end
