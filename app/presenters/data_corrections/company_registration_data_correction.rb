class CompanyRegistrationDataCorrection < DataCorrectionPresenter
  include BasicDataCorrectable

  data_corrects :company_registration, skip_validation: true

  validates :company_registration, presence: true, if: ->(data_correction) {
    LegalForm.company_registration_required?(data_correction.loan.legal_form_id)
  }
end
