class GenericFieldsDataCorrection < DataCorrectionPresenter
  attr_accessor :generic1, :generic2, :generic3, :generic4, :generic5
  attr_accessible :generic1, :generic2, :generic3, :generic4, :generic5

  def change_type
    ChangeType::GenericFields
  end

private

  def update_loan
    loan.generic1 = generic1
    loan.generic2 = generic2
    loan.generic3 = generic3
    loan.generic4 = generic4
    loan.generic5 = generic5
  end

end
