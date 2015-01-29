class DeleteRedundantLoanChanges < ActiveRecord::Migration
  def up
    # Delete any loan changes that don't have any loan change data
    conditions = {
      maturity_date: nil,
      old_maturity_date: nil,
      lump_sum_repayment: nil,
      amount_drawn: nil,
      amount: nil,
      old_amount: nil,
      initial_draw_date: nil,
      old_initial_draw_date: nil,
      initial_draw_amount: nil,
      old_initial_draw_amount: nil,
      repayment_duration: nil,
      old_repayment_duration: nil,
      repayment_frequency_id: nil,
      old_repayment_frequency_id: nil,
    }

    LoanModification.where(type: ['LoanChange', 'DataCorrection']).where(conditions).
      delete_all
  end

  def down
  end
end
