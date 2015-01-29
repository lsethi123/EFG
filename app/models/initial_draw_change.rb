class InitialDrawChange < LoanModification
  ATTRIBUTES_FOR_LOAN = []

  before_validation :set_change_type_id, on: :create

  validates_presence_of :amount_drawn, strict: true

  def change_type_name
    'Initial draw and guarantee'
  end

  private

  def set_change_type_id
    self.change_type_id = nil
  end

  # Initial Draw Change should always be the first loan modification
  # and there can only ever be one per loan
  def set_seq
    self.seq = 0
  end
end
