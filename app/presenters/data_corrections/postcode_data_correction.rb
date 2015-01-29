class PostcodeDataCorrection < DataCorrectionPresenter
  include BasicDataCorrectable
  include PresenterFormatterConcern

  data_corrects :postcode

  format :postcode, with: PostcodeFormatter

  validate :validate_postcode

  private

  def validate_postcode
    errors.add(:postcode, :invalid) unless postcode.full?
  end
end
