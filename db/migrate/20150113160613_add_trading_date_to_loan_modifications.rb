class AddTradingDateToLoanModifications < ActiveRecord::Migration
  def change
    add_column :loan_modifications, :trading_date, :date
    add_column :loan_modifications, :old_trading_date, :date
  end
end
