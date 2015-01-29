class TradingDateDataCorrection < DataCorrectionPresenter
  include BasicDataCorrectable

  data_corrects :trading_date

  def trading_date=(value)
    @trading_date = QuickDateFormatter.parse(value)
  end
end
