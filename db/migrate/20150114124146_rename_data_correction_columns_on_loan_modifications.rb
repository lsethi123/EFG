class RenameDataCorrectionColumnsOnLoanModifications < ActiveRecord::Migration
  def up
    # data correction column names should match their loan counterparts
    rename_column :loan_modifications, :dti_demand_out_amount, :dti_demand_outstanding
    rename_column :loan_modifications, :old_dti_demand_out_amount, :old_dti_demand_outstanding
    rename_column :loan_modifications, :dti_demand_interest, :dti_interest
    rename_column :loan_modifications, :old_dti_demand_interest, :old_dti_interest

    [
      :business_name,
      :old_business_name,
      :facility_letter_date,
      :old_facility_letter_date,
      :sortcode,
      :old_sortcode,
      :dti_demand_outstanding,
      :old_dti_demand_outstanding,
      :dti_interest,
      :old_dti_interest,
      :lending_limit_id,
      :old_lending_limit_id,
      :postcode,
      :old_postcode,
      :lender_reference,
      :old_lender_reference,
      :old_trading_name,
      :trading_name,
      :trading_date,
      :old_trading_date,
      :company_registration,
      :old_company_registration,
    ].each do |column_name|
      rename_column :loan_modifications, column_name, "_legacy_#{column_name}"
    end
  end

  def down
    [
      :_legacy_business_name,
      :_legacy_old_business_name,
      :_legacy_facility_letter_date,
      :_legacy_old_facility_letter_date,
      :_legacy_sortcode,
      :_legacy_old_sortcode,
      :_legacy_dti_demand_outstanding,
      :_legacy_old_dti_demand_outstanding,
      :_legacy_dti_interest,
      :_legacy_old_dti_interest,
      :_legacy_lending_limit_id,
      :_legacy_old_lending_limit_id,
      :_legacy_postcode,
      :_legacy_old_postcode,
      :_legacy_lender_reference,
      :_legacy_old_lender_reference,
      :_legacy_old_trading_name,
      :_legacy_trading_name,
      :_legacy_trading_date,
      :_legacy_old_trading_date,
      :_legacy_company_registration,
      :_legacy_old_company_registration,
    ].each do |column_name|
      rename_column :loan_modifications, column_name, column_name.to_s.gsub(/^_legacy_/, '')
    end

    # data correction column names should match their loan counterparts
    rename_column :loan_modifications, :dti_demand_outstanding, :dti_demand_out_amount
    rename_column :loan_modifications, :old_dti_demand_outstanding, :old_dti_demand_out_amount
    rename_column :loan_modifications, :dti_interest, :dti_demand_interest
    rename_column :loan_modifications, :old_dti_interest, :old_dti_demand_interest
  end
end
