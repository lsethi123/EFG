class AddCompanyRegistrationToLoanModifications < ActiveRecord::Migration
  def change
    add_column :loan_modifications, :company_registration, :string
    add_column :loan_modifications, :old_company_registration, :string
  end
end
