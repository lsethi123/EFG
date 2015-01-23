class AddSubLenderToLoans < ActiveRecord::Migration
  def change
    add_column :loans, :sub_lender, :string
  end
end
