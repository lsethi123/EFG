require 'spec_helper'

describe CompanyRegistrationDataCorrection do
  it_behaves_like 'a basic data correction presenter', :company_registration, '654321', nil, { legal_form_id: LegalForm::PLC.id }

  describe "validations" do
    subject(:data_correction) { FactoryGirl.build(:company_registration_data_correction, loan: loan) }

    LegalForm.all.each do |legal_form|
      context "when legal_form is #{legal_form.name}" do
        let(:loan) { FactoryGirl.build(:loan, legal_form_id: legal_form.id) }

        it "#{legal_form.requires_company_registration ? 'requires' : 'does not require' } company registration number" do
          data_correction.company_registration = nil
          data_correction.valid?.should eql(!legal_form.requires_company_registration)
          data_correction.company_registration = "B1234567890"
          data_correction.should be_valid
        end
      end
    end
  end
end
