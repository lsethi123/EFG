class DeleteEmptyDataCorrections < ActiveRecord::Migration
  def up
    # There are some data corrections with no data changes
    # due to how the old data correction form worked
    # They contain no useful information and so can be safely deleted
    DataCorrection.where(data_correction_changes: nil).destroy_all
  end

  def down
  end
end
