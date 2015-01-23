class SubLenderDataCorrection < DataCorrectionPresenter
  include BasicDataCorrectable

  data_corrects :sub_lender

  delegate :sub_lender_names, to: :loan
end
