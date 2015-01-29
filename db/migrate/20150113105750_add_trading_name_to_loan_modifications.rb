class AddTradingNameToLoanModifications < ActiveRecord::Migration
  def change
    add_column :loan_modifications, :old_trading_name, :string
    add_column :loan_modifications, :trading_name, :string
  end
end
