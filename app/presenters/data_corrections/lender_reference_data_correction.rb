class LenderReferenceDataCorrection < DataCorrectionPresenter
  include BasicDataCorrectable

  data_corrects :lender_reference
end
