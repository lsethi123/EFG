class SortcodeDataCorrection < DataCorrectionPresenter
  include BasicDataCorrectable

  data_corrects :sortcode
end
