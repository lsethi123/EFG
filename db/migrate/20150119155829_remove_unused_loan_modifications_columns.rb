class RemoveUnusedLoanModificationsColumns < ActiveRecord::Migration
  def up
    remove_column :loan_modifications, :_legacy_old_trading_name
    remove_column :loan_modifications, :_legacy_trading_name
    remove_column :loan_modifications, :_legacy_trading_date
    remove_column :loan_modifications, :_legacy_old_trading_date
    remove_column :loan_modifications, :_legacy_company_registration
    remove_column :loan_modifications, :_legacy_old_company_registration
  end

  def down
    add_column :loan_modifications, :_legacy_old_trading_name, :string
    add_column :loan_modifications, :_legacy_trading_name, :string
    add_column :loan_modifications, :_legacy_trading_date, :date
    add_column :loan_modifications, :_legacy_old_trading_date, :date
    add_column :loan_modifications, :_legacy_company_registration, :string
    add_column :loan_modifications, :_legacy_old_company_registration, :string
  end
end
