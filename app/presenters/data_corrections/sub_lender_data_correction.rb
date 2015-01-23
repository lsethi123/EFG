class SubLenderDataCorrection < DataCorrectionPresenter
  include BasicDataCorrectable

  data_corrects :sub_lender, skip_validation: true

  delegate :sub_lender_names, to: :loan

  validates_inclusion_of :sub_lender, in: :sub_lender_names, if: :lender_has_sub_lenders?

  private

  def lender_has_sub_lenders?
    sub_lender_names.present?
  end

end
